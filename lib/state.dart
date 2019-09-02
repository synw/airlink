import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pedantic/pedantic.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:kvsql/kvsql.dart';
import 'package:dio/dio.dart';
import "models/filesystem.dart";
import "models/data_link.dart";
import 'server/server.dart';
import 'conf.dart';
import 'log.dart';

AppState state;

class AppState extends Model {
  AppState({this.verbose = false}) {
    assert(db.db.isReady);
    store = KvStore(db: db.db, inMemory: true, verbose: true);
  }

  final bool verbose;

  Dio httpClient;
  DataLink activeDataLink;
  String serverIp;
  var fileServer = FileServer();
  bool serverIsConfigured = false;
  bool remoteViewActive = false;
  String remotePath = "";
  List<DirectoryItem> directoryItems;
  RemoteDirectoryListing remoteDirectoryListing;

  final Completer<Null> _readyCompleter = Completer<Null>();
  KvStore store;

  Future<Null> get onReady => _readyCompleter.future;

  String get serverName => store.selectSync<String>("server_name");
  set serverName(String value) {
    store.put<String>("server_name", value);
    _notify("set server name to $value");
  }

  String get serverApiKey => store.selectSync<String>("api_key");
  set serverApiKey(String value) {
    store.put<String>("api_key", value);
    _notify("set api key to $value");
  }

  String get localPath => store.selectSync<String>("local_path");
  set localPath(String value) {
    store.put<String>("local_path", value);
    _notify("set local path to $value");
  }

  String get page => _getPage();

  Directory get rootDirectory => _getRootDirectory();
  set rootDirectory(Directory directory) {
    store.put<String>("root_path", directory.path);
    _notify("set root path to ${directory.path}");
  }

  int get activeDataLinkId => store.selectSync<int>("active_datalink_id");
  set activeDataLinkId(int v) => store.put<int>("active_datalink_id", v);

  Future<void> init() async {
    await store.onReady;
    // active data link
    activeDataLink = await db.getActiveDataLink(activeDataLinkId);
    //int activeDataLinkId = await db.getActiveDataLinkId();
    print("ACTIVE DL $activeDataLink");
    if (activeDataLink != null) {
      httpClient = _getHttpClient();
    }
    //log.debug("STATE ADL $activeDataLink");
    // server directories
    //String rootDirectoryStr = store.select("root_directory");
    //if (rootDirectoryStr != null) rootDirectory = Directory(rootDirectoryStr);
    //serverName = await store.select("server_name");
    //serverApiKey = await store.select("api_key");
    localPath ??= "/";
    checkServerConfig();
    print("STATE INITIALIZED:");
    print("- Server conf: $serverIsConfigured");
    print("- Root dir: $rootDirectory");
    _readyCompleter.complete();
    _notify("init state");
  }

  void navigate(BuildContext context, String route) {
    Navigator.of(context).pushNamed(route);
    store.push("page", route);
  }

  void navigateReplacement(BuildContext context, String route) {
    Navigator.of(context).pushReplacementNamed(route);
    store.push("page", route);
  }

  void toggleRemoteView() {
    remoteViewActive = !remoteViewActive;
    _notify("toggle remote view active to $remoteViewActive");
  }

  void setRemoteDirectoryListing(RemoteDirectoryListing listing) {
    remoteDirectoryListing = listing;
    _notify("set remote directory listing: $listing");
  }

  void setDirectoryListing(List<DirectoryItem> items) {
    directoryItems = items;
    _notify("set directory listing: $items");
  }

  void checkServerConfig() {
    if (rootDirectory != null &&
        serverName != null &&
        serverIp != null &&
        serverApiKey != null) {
      serverIsConfigured = true;
    } else {
      serverIsConfigured = false;
    }

    _notify("check server config");
  }

  Future<void> setActiveDataLinkNull() async {
    store.push("active_data_link", "NULL");
    _notify("set active data link to null");
  }

  Future<void> setActiveDataLink(
      {@required DataLink dataLink, @required BuildContext context}) async {
    assert(dataLink != null);
    activeDataLink = dataLink;
    print("ACTIVE DATA LINK SET: $activeDataLink");
    httpClient = _getHttpClient();
    // persist
    try {
      // data
      await db.upsertDataLink(dataLink: dataLink);
      // state
      final id = await db.getActiveDataLinkId(dataLink.name);
      activeDataLinkId = id;
    } catch (e) {
      throw ('Can not update persistant state $e');
    }
    unawaited(log.debug("STATE active dl SET: $activeDataLink"));
    _notify("set active data link to $activeDataLink");
  }

  Dio _getHttpClient() {
    assert(activeDataLink != null);
    return Dio(BaseOptions(
      connectTimeout: 5000,
      receiveTimeout: 10000,
      headers: <String, dynamic>{
        HttpHeaders.authorizationHeader: "Bearer ${activeDataLink.apiKey}",
        "user-agent": "Airlink"
      },
    ));
  }

  void _notify(String msg) {
    if (verbose) {
      log.debug("STATE CHANGE: $msg");
    }
    notifyListeners();
  }

  @override
  String toString() {
    return "$activeDataLink / $httpClient";
  }

  Directory _getRootDirectory() {
    final rootDirectoryStr = store.selectSync<String>("root_path");
    if (rootDirectoryStr != null) {
      return Directory(rootDirectoryStr);
    }
    return null;
  }

  String _getPage() {
    String s;
    final value = store.selectSync<String>("page");
    switch ("$value" == "null") {
      case false:
        s = value;
        break;
      default:
        s = "/file_explorer";
    }
    return s;
  }
}

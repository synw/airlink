import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:persistent_state/persistent_state.dart';
import 'package:dio/dio.dart';
import "models/filesystem.dart";
import "models/data_link.dart";
import 'server/server.dart';
import 'conf.dart';
import 'log.dart';

AppState state;

class AppState extends Model {
  AppState() {
    assert(db.db.isReady);
    store = PersistentState(db: db.db, table: "state", verbose: true);
    store.init();
  }

  Dio httpClient;
  DataLink activeDataLink;
  String serverIp;
  var fileServer = FileServer();
  bool serverIsConfigured = false;
  bool remoteViewActive = false;
  String remotePath = "/";
  List<DirectoryItem> directoryItems;
  RemoteDirectoryListing remoteDirectoryListing;

  final Completer<Null> _readyCompleter = Completer<Null>();
  PersistentState store;

  Future<Null> get onReady => _readyCompleter.future;

  String get serverName => store.select("server_name");
  set serverName(String value) {
    store.mutate("server_name", value);
    notifyListeners();
  }

  String get serverApiKey => store.select("api_key");
  set serverApiKey(String value) {
    store.mutate("api_key", value);
    notifyListeners();
  }

  String get localPath => store.select("local_path");
  set localPath(String value) {
    store.mutate("local_path", value);
    notifyListeners();
  }

  String get page => _getPage();

  Directory get rootDirectory => _getRootDirectory();
  set rootDirectory(Directory directory) {
    store.mutate("root_path", directory.path);
    notifyListeners();
  }

  Future<void> init() async {
    await store.onReady;
    // active data link
    activeDataLink = await db.getActiveDataLink();
    //int activeDataLinkId = await db.getActiveDataLinkId();
    print("ACTIVE DL $activeDataLink");
    if (activeDataLink != null) httpClient = _getHttpClient();
    //log.debug("STATE ADL $activeDataLink");
    // server directories
    //String rootDirectoryStr = store.select("root_directory");
    //if (rootDirectoryStr != null) rootDirectory = Directory(rootDirectoryStr);
    //serverName = await store.select("server_name");
    //serverApiKey = await store.select("api_key");
    checkServerConfig();
    print("STATE INITIALIZED:");
    print("- Server conf: $serverIsConfigured");
    print("- Root dir: $rootDirectory");
    _readyCompleter.complete();
    notifyListeners();
  }

  void navigate(BuildContext context, String route) {
    Navigator.of(context).pushNamed(route);
    //store.mutate("page", route);
  }

  void navigateReplacement(BuildContext context, String route) {
    Navigator.of(context).pushReplacementNamed(route);
    store.mutate("page", route);
  }

  void toggleRemoteView() {
    remoteViewActive = !remoteViewActive;
  }

  void setRemoteDirectoryListing(RemoteDirectoryListing listing) {
    remoteDirectoryListing = listing;
    notifyListeners();
  }

  void setDirectoryListing(List<DirectoryItem> items) {
    directoryItems = items;
    notifyListeners();
  }

  void checkServerConfig() {
    if (rootDirectory != null &&
        serverName != null &&
        serverIp != null &&
        serverApiKey != null) {
      serverIsConfigured = true;
    } else
      serverIsConfigured = false;
    notifyListeners();
  }

  Future<void> setActiveDataLinkNull() async {
    store.mutate("active_data_link", "NULL");
    notifyListeners();
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
      db.upsertDataLink(dataLink: dataLink);
      // state
      int id = await db.getActiveDataLinkId(dataLink.name);
      store.mutate("active_data_link", id.toString());
    } catch (e) {
      throw ('Can not update persistant state $e');
    }
    log.debug("STATE active dl SET: $activeDataLink");
    notifyListeners();
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

  @override
  String toString() {
    return "$activeDataLink / $httpClient";
  }

  Directory _getRootDirectory() {
    String rootDirectoryStr = store.select("root_path");
    if (rootDirectoryStr != null) return Directory(rootDirectoryStr);
    return null;
  }

  String _getPage() {
    String s;
    String value = store.select("page");
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

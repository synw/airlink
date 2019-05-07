import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:dio/dio.dart';
import "models/filesystem.dart";
import "models/data_link.dart";
import 'server/server.dart';
import 'conf.dart';
import 'log.dart';

var state = AppState();

class AppState extends Model {
  AppState({this.httpClient, this.activeDataLink});

  Dio httpClient;
  DataLink activeDataLink;
  Directory uploadDirectory;
  Directory rootDirectory;
  String serverName;
  String serverIp;
  String serverApiKey;
  var fileServer = FileServer();
  bool serverIsConfigured = false;
  bool remoteViewActive = false;
  String remotePath = "/";
  String localPath = "/";
  List<DirectoryItem> directoryItems;

  final Completer<Null> _readyCompleter = Completer<Null>();

  Future<Null> get onReady => _readyCompleter.future;

  Future<void> init() async {
    await onConfReady;
    // active data link
    int activeDataLinkId = await db.getActiveDataLinkId();
    //print("ACTIVE ID $activeDataLinkId");
    if (activeDataLinkId != null) {
      activeDataLink = await db.getDataLink(activeDataLinkId);
      httpClient = _getHttpClient();
    }
    //log.debug("STATE ADL $activeDataLink");
    // server directories
    Map<String, String> initialState = await db.getInitialState();
    if (initialState["root_path"] != null)
      rootDirectory = Directory(initialState["root_path"]);
    if (initialState["upload_path"] != null)
      uploadDirectory = Directory(initialState["upload_path"]);
    if (initialState["server_name"] != null)
      serverName = initialState["server_name"];
    if (initialState["server_api_key"] != null)
      serverApiKey = initialState["server_api_key"];
    checkServerConfig();
    print("STATE INITIALIZED:");
    print("- Server conf: $serverIsConfigured");
    print("- Root dir: $rootDirectory");
    print("- Upload dir $uploadDirectory");
    _readyCompleter.complete();
    notifyListeners();
  }

  void toggleRemoteView() {
    remoteViewActive = !remoteViewActive;
    print("REMOTE VIES $remoteViewActive");
    notifyListeners();
  }

  void setRemoteView(bool active) {
    remoteViewActive = active;
    notifyListeners();
  }

  void setDirectoryListing(List<DirectoryItem> items) {
    directoryItems = items;
    notifyListeners();
  }

  void setLocalPath(String path) {
    localPath = path;
    notifyListeners();
  }

  void checkServerConfig() {
    if (!serverIsConfigured) {
      if (rootDirectory != null && uploadDirectory != null)
        serverIsConfigured = true;
    } else
      serverIsConfigured = false;
    notifyListeners();
  }

  Future<void> setServerApiKey(String key) async {
    serverApiKey = key;
    try {
      db.setServerApiKey(key);
      notifyListeners();
    } catch (e) {
      throw (e);
    }
  }

  Future<void> setServerName(String name) async {
    serverName = name;
    try {
      db.setServerName(name);
      notifyListeners();
    } catch (e) {
      throw (e);
    }
  }

  Future<void> setServerRootDirectory(Directory directory) async {
    rootDirectory = directory;
    try {
      db.setRootDirectory(directory.path);
      notifyListeners();
    } catch (e) {
      throw (e);
    }
  }

  Future<void> setServerUploadDirectory(Directory directory) async {
    uploadDirectory = directory;
    try {
      db.setUploadDirectory(directory.path);
      notifyListeners();
    } catch (e) {
      throw (e);
    }
  }

  Future<void> setActiveDataLinkNull() async {
    try {
      await db.setActiveDataLinkStateNull();
      activeDataLink = null;
    } catch (e) {
      throw (e);
    }
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
      await db.updateActiveDataLinkState(dataLink: dataLink);
    } catch (e) {
      throw ('Can not update persistant state');
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
}

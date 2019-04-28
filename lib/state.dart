import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:dio/dio.dart';
import "models/data_link.dart";
import 'server/server.dart';
import 'conf.dart';
import 'log.dart';

var state = AppState();

class AppState extends Model {
  AppState({this.httpClient, this.activeDataLink});

  Dio httpClient;
  DataLink activeDataLink;
  Directory serverRootDirectory;
  Directory serverUploadDirectory;
  var fileServer = FileServer();
  bool serverIsConfigured = false;
  bool remoteViewActive = false;
  String remotePath = "/";

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
    serverRootDirectory = Directory(initialState["root_path"]);
    serverUploadDirectory = Directory(initialState["upload_path"]);
    checkServerConfig();
    print("STATE INITIALIZED:");
    print("- Server conf: $serverIsConfigured");
    print("- Root dir: $serverRootDirectory");
    print("- Upload dir $serverUploadDirectory");
    _readyCompleter.complete();
    notifyListeners();
  }

  void checkServerConfig() {
    if (!serverIsConfigured) {
      if (serverRootDirectory != null && serverUploadDirectory != null)
        serverIsConfigured = true;
    } else
      serverIsConfigured = false;
    notifyListeners();
  }

  Future<void> setServerRootDirectory(Directory directory) async {
    serverRootDirectory = directory;
    try {
      db.setRootDirectory(directory.path);
    } catch (e) {
      throw (e);
    }
    notifyListeners();
  }

  Future<void> setServerUploadDirectory(Directory directory) async {
    serverUploadDirectory = directory;
    try {
      db.setUploadDirectory(directory.path);
    } catch (e) {
      throw (e);
    }
    notifyListeners();
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
        HttpHeaders.authorizationHeader: "Bearer ${activeDataLink.apiKey}"
      },
    ));
  }

  @override
  String toString() {
    return "$activeDataLink / $httpClient";
  }
}

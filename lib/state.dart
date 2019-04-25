import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import "models/data_link.dart";
import 'conf.dart';
import 'log.dart';

var state = AppState();

class AppState {
  AppState({this.httpClient, this.activeDataLink});

  Dio httpClient;
  DataLink activeDataLink;

  bool remoteViewActive = false;
  String remotePath = "/";

  final Completer<Null> _readyCompleter = Completer<Null>();

  Future<Null> get onReady => _readyCompleter.future;

  Future<void> init() async {
    await onConfReady;
    int activeDataLinkId = await db.getActiveDataLinkId();
    print("ACTIVE ID $activeDataLinkId");
    if (activeDataLinkId != null) {
      activeDataLink = await db.getDataLink(activeDataLinkId);
      httpClient = getHttpClient();
    }
    log.debug("STATE ADL $activeDataLink");
    _readyCompleter.complete();
  }

  Future<void> setActiveDataLink(
      {@required DataLink dataLink, @required BuildContext context}) async {
    assert(dataLink != null);
    activeDataLink = dataLink;
    print("ACTIVE DATA LINK SET: $activeDataLink");
    httpClient = getHttpClient();
    // persist
    try {
      await db.updateActiveDataLinkState(dataLink: dataLink);
    } catch (e) {
      throw ('Can not update persistant state');
    }
    log.debug("STATE active dl: $activeDataLink");
  }

  Dio getHttpClient() {
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

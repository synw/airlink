import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'state.dart';
import 'conf.dart';
import 'log.dart';

class Downloader {
  final _completedController = StreamController<bool>();
  dynamic callback;

  Stream<bool> get completedController => _completedController.stream;

  void dispose() {
    _completedController.close();
    callback = null;
  }

  Future<void> download(String url, String path, BuildContext context) async {
    await FlutterDownloader.enqueue(
            headers: {"Authorization": "Bearer ${state.activeDataLink.apiKey}"},
            url: url,
            savedDir: externalDirectory.path + path,
            showNotification: true)
        .catchError((dynamic e) {
      log.errorScreen("Can not enqueue download task", context: context);
    });
    await FlutterDownloader.loadTasks().catchError((dynamic e) {
      log.errorScreen("Can not download file", context: context);
    });
    callback = FlutterDownloader.registerCallback(
        (String id, DownloadTaskStatus status, int progress) async {
      if (status == DownloadTaskStatus.complete) {
        _completedController.sink.add(true);
      }
    });
  }
}

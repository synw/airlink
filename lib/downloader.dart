import 'dart:async';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'state.dart';
import 'conf.dart';

class Downloader {
  final _completedController = StreamController<bool>();
  dynamic callback;

  Stream<bool> get completedController => _completedController.stream;

  void dispose() {
    _completedController.close();
    callback = null;
  }

  Future<void> download(String url, String path) async {
    await FlutterDownloader.enqueue(
        headers: {"Authorization": "Bearer ${state.activeDataLink.apiKey}"},
        url: url,
        savedDir: externalDirectory.path + path,
        showNotification: true);
    await FlutterDownloader.loadTasks();
    callback = FlutterDownloader.registerCallback(
        (String id, DownloadTaskStatus status, int progress) async {
      if (status == DownloadTaskStatus.complete) {
        _completedController.sink.add(true);
      }
    });
  }
}

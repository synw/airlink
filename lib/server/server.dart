import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import '../models/data_link.dart';
import '../log.dart';

class FileServer {
  FileServer();

  DataLink _dataLink;
  Directory _rootDirectory;
  Directory _uploadDirectory;

  bool _isInitialized = false;
  bool _isRunning = false;

  Stream<HttpRequest> _server;
  StreamSubscription _serverSub;
  final Completer<Null> _readyCompleter = Completer<Null>();

  Future<Null> get onReady => _readyCompleter.future;
  bool get isInitialized => _isInitialized;
  bool get isRunning => _isRunning;

  void init(
      {@required DataLink dataLink,
      @required Directory rootDirectory,
      @required Directory uploadDirectory}) {
    print("INIT SERVER AT $dataLink");
    _rootDirectory = rootDirectory;
    _uploadDirectory = uploadDirectory;
    _dataLink = dataLink;
    HttpServer.bind(_dataLink.url, int.parse(_dataLink.port))
        .then((HttpServer server) {
      _server = server.asBroadcastStream();
      _readyCompleter.complete();
      _isInitialized = true;
    });
  }

  void _notFound(HttpResponse response) {
    response.write('Not found');
    response.statusCode = HttpStatus.notFound;
    response.close();
  }

  void _unauthorized(HttpResponse response) {
    response.write('Unauthorized');
    response.statusCode = HttpStatus.unauthorized;
    response.close();
  }

  void _handlePost(HttpRequest request) async {
    print("POST REQUEST: ${request.uri.path} / ${request.headers.contentType}");
    // verify authorization
    String tokenString = "Bearer ${_dataLink.apiKey}";
    try {
      if (request.headers.value(HttpHeaders.authorizationHeader) !=
          tokenString) {
        print("Unauthorized");
        _unauthorized(request.response);
      }
    } catch (_) {
      log.error("Can not get authorization header");
      _unauthorized(request.response);
    }
    // process request
    String content = await request.transform(const Utf8Decoder()).join();
    Map<dynamic, dynamic> data;
    try {
      data = jsonDecode(content) as Map;
    } catch (e) {
      log.error("DECODING ERROR $e");
    }
    String path = data["path"].toString();
    String dirPath;
    (path == "/" || path == "")
        ? dirPath = _rootDirectory.path
        : dirPath = _rootDirectory.path + path;
    Directory dir = Directory(dirPath);
    HttpResponse response = request.response;
    if (dir == null) _notFound(response);
    response.headers.contentType =
        new ContentType("application", "json", charset: "utf-8");
    var dirListing = await getDirectoryListing(dir);
    response.statusCode = HttpStatus.ok;
    response.write(jsonEncode(dirListing));
    response.close();
  }

  void start() async {
    assert(_isInitialized);
    if (_isRunning) log.warning("The server is already running");
    await onReady;
    log.info("STARTING SERVER");
    _serverSub = _server.listen((request) {
      switch (request.method) {
        case 'POST':
          _handlePost(request);
          break;
        default:
          request.response.statusCode = HttpStatus.methodNotAllowed;
          request.response.close();
      }
    });
    _isRunning = true;
  }

  void stop() async {
    if (_isRunning) {
      log.info("STOPPING SERVER");
      await _serverSub.cancel();
      _isRunning = false;
    }
    log.warning("The server is already running");
  }

  Future<Map<String, List<Map<String, dynamic>>>> getDirectoryListing(
      Directory dir) async {
    List contents = dir.listSync()..sort((a, b) => a.path.compareTo(b.path));
    var dirs = <Map<String, String>>[];
    var files = <Map<String, dynamic>>[];
    for (var fileOrDir in contents) {
      if (fileOrDir is Directory) {
        var dir = Directory("${fileOrDir.path}");
        dirs.add({
          "name": path.basename(dir.path),
        });
      } else {
        var file = File("${fileOrDir.path}");
        files.add(<String, dynamic>{
          "name": path.basename(file.path),
          "size": file.lengthSync()
        });
      }
    }
    return {"files": files, "directories": dirs};
  }
}

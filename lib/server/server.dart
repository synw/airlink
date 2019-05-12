import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:body_parser/body_parser.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import '../models/data_link.dart';
import '../models/server.dart';
import '../log.dart';

class FileServer {
  DataLink _dataLink;
  Directory _rootDirectory;

  bool _isInitialized = false;
  bool _isRunning = false;
  List<ServerLog> _logs = [];

  Stream<HttpRequest> _server;
  StreamSubscription _serverSub;
  final Completer<Null> _readyCompleter = Completer<Null>();
  StreamController<ServerLog> _serverLog;

  Stream<ServerLog> get serverLog => _serverLog.stream;
  List<ServerLog> get logs => _logs;

  Future<Null> get onReady => _readyCompleter.future;
  bool get isInitialized => _isInitialized;
  bool get isRunning => _isRunning;

  void init({@required DataLink dataLink, @required Directory rootDirectory}) {
    print("INIT SERVER AT $dataLink");
    _rootDirectory = rootDirectory;
    _dataLink = dataLink;
    HttpServer.bind(_dataLink.url, int.parse(_dataLink.port))
        .then((HttpServer s) {
      _server = s.asBroadcastStream();
      _readyCompleter.complete();
      _isInitialized = true;
    });
  }

  void _unauthorized(HttpRequest request, String msg) {
    request.response.statusCode = HttpStatus.unauthorized;
    request.response.write(jsonEncode({"Status": "Unauthorized"}));
    request.response.close();
    emitServerLog(
        logClass: LogMessageClass.warning,
        message: msg,
        statusCode: request.response.statusCode,
        requestUrl: request.uri.path);
  }

  void _notFound(HttpRequest request, String msg) {
    request.response.statusCode = HttpStatus.notFound;
    request.response.write(jsonEncode({"Status": msg}));
    request.response.close();
    emitServerLog(
        logClass: LogMessageClass.warning,
        message: msg,
        statusCode: request.response.statusCode,
        requestUrl: request.uri.path);
  }

  bool verifyToken(HttpRequest request) {
    String tokenString = "Bearer ${_dataLink.apiKey}";
    print("HEADERS");
    print("${request.headers}");
    try {
      if (request.headers.value(HttpHeaders.authorizationHeader) !=
          tokenString) {
        String msg = "Unauthorized request";
        log.warning(msg);
        _unauthorized(request, msg);
        return false;
      }
    } catch (_) {
      String msg = "Can not get authorization header";
      log.error(msg);
      _unauthorized(request, msg);
      return false;
    }
    return true;
  }

  void _handleGet(HttpRequest request) async {
    // verify authorization
    bool authorized = verifyToken(request);
    if (!authorized) return;
    // process request
    String filePath = _rootDirectory.path + request.uri.path;
    log.debug("REQUEST $filePath");

    File file = File(filePath);
    if (!file.existsSync()) {
      _notFound(request, "File not found");
      return;
    }
    log.info(request.uri.path);
    file.openRead().pipe(request.response).then((dynamic _) {
      log.debug("OK");
      emitServerLog(
          logClass: LogMessageClass.success,
          message: "",
          statusCode: request.response.statusCode,
          requestUrl: request.uri.path);
    }).catchError((dynamic e) {
      String msg = "Can not read file ${file.path}";
      log.error(msg);
      emitServerLog(
          logClass: LogMessageClass.error,
          message: msg,
          statusCode: request.response.statusCode,
          requestUrl: request.uri.path);
    });
  }

  void upload(dynamic content) {
    print("UPLOAD");
    print("${content.runtimeType}");
    print("$content");
  }

  void _handlePost(HttpRequest request) async {
    log.debug(
        "POST REQUEST: ${request.uri.path} / ${request.headers.contentType}");
    // verify authorization
    bool authorized = verifyToken(request);
    if (!authorized) return;
    // process request
    //String content = await request.transform(const Utf8Decoder()).join();
    BodyParseResult body = await parseBody(request);
    var content = json.encode(body.body);
    Map<dynamic, dynamic> data;
    try {
      data = jsonDecode(content) as Map;
      print("DATA $data");
    } catch (e) {
      log.error("DECODING ERROR $e");
      _notFound(request, "Decoding error");
      return;
    }
    if (!data.containsKey('path')) {
      if (data.containsKey("file")) {
        upload(data["file"]);
      } else {
        log.error("Wrong action");
        _notFound(request, "Wrong action");
        return;
      }
    }
    String path = data["path"].toString();
    String dirPath;
    (path == "/" || path == "")
        ? dirPath = _rootDirectory.path
        : dirPath = _rootDirectory.path + path;
    Directory dir = Directory(dirPath);
    HttpResponse response = request.response;
    if (dir == null) {
      _notFound(request, "Directory not found");
      return;
    }
    response.headers.contentType =
        new ContentType("application", "json", charset: "utf-8");
    var dirListing = await getDirectoryListing(dir);
    response.statusCode = HttpStatus.ok;
    response.write(jsonEncode(dirListing));
    response.close();
    // log
    emitServerLog(
        logClass: LogMessageClass.success,
        message: "",
        statusCode: response.statusCode,
        requestUrl: path);
  }

  Future<bool> start(BuildContext context) async {
    assert(_isInitialized);
    if (_isRunning) {
      log.warningScreen("The server is already running", context: context);
      return false;
    }
    _serverLog = StreamController<ServerLog>.broadcast();
    await onReady;
    log.info("STARTING SERVER");
    _serverSub = _server.listen((request) {
      log.debug("REQUEST ${request.uri.path} / ${request.headers.contentType}");
      switch (request.method) {
        case 'POST':
          _handlePost(request);
          break;
        case 'GET':
          _handleGet(request);
          break;
        default:
          request.response.statusCode = HttpStatus.methodNotAllowed;
          request.response.close();
          emitServerLog(
              logClass: LogMessageClass.warning,
              message: "Method not allowed ${request.method}",
              statusCode: request.response.statusCode,
              requestUrl: request.uri.path);
          return false;
      }
    });
    _isRunning = true;
    return true;
  }

  Future<bool> stop(BuildContext context) async {
    if (_isRunning) {
      log.info("STOPPING SERVER");
      await _serverSub.cancel();
      _isRunning = false;
      _serverLog.close();
      return true;
    }
    log.warningScreen("The server is already running", context: context);
    return false;
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

  void emitServerLog(
      {@required LogMessageClass logClass,
      @required String requestUrl,
      @required String message,
      @required int statusCode}) async {
    ServerLog logItem = ServerLog(
        statusCode: statusCode,
        requestUrl: requestUrl,
        message: message,
        logClass: logClass);
    switch (logItem.logClass) {
      case LogMessageClass.success:
        log.info(logItem.toString());
        break;
      case LogMessageClass.error:
        log.error(logItem.toString());
        break;
      case LogMessageClass.warning:
        log.warning(logItem.toString());
    }
    _serverLog.sink.add(logItem);
    _logs.add(logItem);
  }
}

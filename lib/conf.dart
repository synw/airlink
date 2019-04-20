import 'dart:io';
import 'package:dio/dio.dart';
import 'dart:async';
import 'package:err/err.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlcool/sqlcool.dart';
import 'settings/db.dart';

String apiKey;
String serverUrl;

bool remoteViewActive = false;
Directory externalDirectory;
String remotePath = "/";

bool serverConfigured;

final settingsDb = Db();

var dio = new Dio(BaseOptions(
  connectTimeout: 5000,
  receiveTimeout: 10000,
  headers: {HttpHeaders.authorizationHeader: "Bearer $apiKey"},
));

var log = ErrRouter(
    terminalColors: true,
    errorRoute: [ErrRoute.screen, ErrRoute.console],
    warningRoute: [ErrRoute.screen, ErrRoute.console],
    infoRoute: [ErrRoute.screen, ErrRoute.console]);

Completer<Null> _readyCompleter = Completer<Null>();

Future<Null> get onConfReady => _readyCompleter.future;

initConf() async {
  initSettingsDb(db: settingsDb, path: "settings.sqlite");
  externalDirectory = await getExternalStorageDirectory();
  await settingsDb.onReady;
  getSettingsValues(settingsDb).then((row) {
    String protocol;
    row["https"] ? protocol = "https" : protocol = "http";
    serverUrl = "$protocol://${row["server_url"]}:${row["port"]}";
    apiKey = row["api_key"];
    serverConfigured = row["configured"];
    _readyCompleter.complete();
  });
}

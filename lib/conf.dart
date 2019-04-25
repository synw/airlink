import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'settings/db.dart';

var db = DataBase();
Directory externalDirectory;

Completer<Null> _readyCompleter = Completer<Null>();

Future<Null> get onConfReady => _readyCompleter.future;

Future<void> initConf() async {
  externalDirectory = await getExternalStorageDirectory();
  await db.init(path: "settings.sqlite");
  _readyCompleter.complete();
}

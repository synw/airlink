import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'db.dart';

var db = DataBase();
Directory externalDirectory;
Directory documentsDirectory;

Completer<Null> _readyCompleter = Completer<Null>();

Future<Null> get onConfReady => _readyCompleter.future;

Future<void> initConf() async {
  externalDirectory = await getExternalStorageDirectory();
  documentsDirectory = await getApplicationDocumentsDirectory();
  await db.init(path: "settings.sqlite");
  _readyCompleter.complete();
}

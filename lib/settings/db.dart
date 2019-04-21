import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:sqlcool/sqlcool.dart';

Future<void> initSettingsDb({@required Db db, @required String path}) async {
  try {
    String q = """
    CREATE TABLE setting (
    id INTEGER PRIMARY KEY,
    server_url VARCHAR(255) NOT NULL,
    port INTEGER NOT NULL DEFAULT 8084,
    api_key VARCHAR(255) NOT NULL,
    https BOOLEAN NOT NULL DEFAULT true,
    configured BOOLEAN NOT NULL DEFAULT false)""";
    String q2 =
        """INSERT INTO setting VALUES(1, "", 8084, "", "false", "false")""";
    await db.init(path: path, queries: [q, q2], verbose: true);
  } catch (e) {
    throw (e);
  }
}

Future<Map<String, dynamic>> getSettingsValues(Db db) async {
  Map<String, dynamic> row;
  var result = await db.select(
      table: "setting",
      where: "id=1",
      columns: "server_url,port,api_key,https,configured");
  bool protocol;
  row = result[0];
  var endResult = <String, dynamic>{};
  endResult["server_url"] = row["server_url"];
  endResult["port"] = row["port"];
  endResult["api_key"] = row["api_key"];
  (row["https"] == "true") ? protocol = true : protocol = false;
  bool conf;
  (row["configured"] == "true") ? conf = true : conf = false;
  endResult["https"] = protocol;
  endResult["configured"] = conf;
  return endResult;
}

Future<void> saveSettings(
    {@required Db db,
    @required String serverUrl,
    @required int port,
    @required String apiKey,
    @required bool https}) async {
  try {
    await db.update(
        table: "setting",
        where: "id=1",
        row: {
          "server_url": serverUrl,
          "api_key": apiKey,
          "port": "$port",
          "https": "$https",
          "configured": "true"
        },
        verbose: true);
  } catch (e) {
    throw (e);
  }
}

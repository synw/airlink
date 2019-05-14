import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:sqlcool/sqlcool.dart';
import "models/data_link.dart";

class DataBase {
  final db = Db();

  List<DbTable> schema() {
    DbTable dataLink = DbTable("data_link")
      ..varchar("name")
      ..varchar("url")
      ..integer("port", defaultValue: 8084)
      ..varchar("api_key")
      ..varchar("protocol", check: 'protocol="http" OR protocol="https"')
      ..varchar("type", check: 'type="device" OR type="server"')
      ..index("name");
    DbTable state = DbTable("state")
      ..varchar("root_path", nullable: true)
      ..varchar("server_name", nullable: true)
      ..varchar("local_path", defaultValue: '"/"')
      ..varchar("api_key", nullable: true)
      ..varchar("page", nullable: true)
      ..foreignKey("active_data_link", reference: "data_link", nullable: true);
    return <DbTable>[dataLink, state];
  }

  Future<void> init({@required String path}) async {
    try {
      String q4 = """INSERT INTO state(id) VALUES(1)""";
      await db.init(path: path, schema: schema(), queries: [q4], verbose: true);
      assert(db.schema != null);
    } catch (e) {
      throw (e);
    }
  }

  /*Future<void> setServerApiKey(String key) async {
    try {
      Map<String, String> row = {"server_api_key": key};
      db.update(table: "state", where: "id=1", row: row);
    } catch (e) {
      throw (e);
    }
  }

  Future<void> setServerName(String name) async {
    try {
      Map<String, String> row = {"server_name": name};
      db.update(table: "state", where: "id=1", row: row);
    } catch (e) {
      throw (e);
    }
  }

  Future<void> setRootDirectory(String dirPath) async {
    try {
      Map<String, String> row = {"root_path": dirPath};
      db.update(table: "state", where: "id=1", row: row);
    } catch (e) {
      throw (e);
    }
  }

  Future<void> setUploadDirectory(String dirPath) async {
    try {
      Map<String, String> row = {"upload_path": dirPath};
      db.update(table: "state", where: "id=1", row: row);
    } catch (e) {
      throw (e);
    }
  }

  Future<Map<String, String>> getInitialState() async {
    Map<String, String> result = {
      "root_path": null,
      "upload_path": null,
      "server_name": null,
      "server_api_key": null
    };
    try {
      List<Map<String, dynamic>> res = await db.select(
          table: "state",
          where: "id=1",
          columns: "upload_path,root_path,server_name,server_api_key");
      if (res[0]["upload_path"].toString() != "null")
        result["upload_path"] = res[0]["upload_path"].toString();
      if (res[0]["root_path"].toString() != "null")
        result["root_path"] = res[0]["root_path"].toString();
      if (res[0]["server_name"].toString() != "null")
        result["server_name"] = res[0]["server_name"].toString();
      if (res[0]["server_api_key"].toString() != "null")
        result["server_api_key"] = res[0]["server_api_key"].toString();
    } catch (e) {
      throw (e);
    }
    return result;
  }*/

  Future<DataLink> getDataLink(int id) async {
    DataLink dl;
    try {
      List<Map<String, dynamic>> res =
          await db.select(table: "data_link", where: 'id=$id');
      if (res.isEmpty) return null;
      dl = DataLink.fromJson(res[0]);
    } catch (e) {
      throw (e);
    }
    return dl;
  }

  Future<int> getActiveDataLinkId() async {
    List<Map<String, dynamic>> result = await db.select(
        table: "state", where: "id=1", columns: "active_data_link");
    print("Q $result");
    return int.tryParse(result[0]["active_data_link"].toString());
  }

  Future<List<DataLink>> getDataLinks() async {
    var result = await db.select(table: "data_link", verbose: true);
    var dataLinks = <DataLink>[];
    result.forEach((Map<String, dynamic> item) {
      dataLinks.add(DataLink.fromJson(item));
    });
    return dataLinks;
  }

  Future<void> updateActiveDataLinkState({DataLink dataLink}) async {
    Map<String, String> row = {};
    List<Map<String, dynamic>> adl = await db.select(
        table: "data_link", columns: "id", where: 'name="${dataLink.name}"');
    if (adl.isEmpty) throw ("Can not find active data link");
    row["active_data_link"] = adl[0]["id"].toString();
    try {
      int updated = await db.update(table: "state", where: "id=1", row: row);
      print("DB ACTIVE DATA LINK UPDATED: $updated");
    } catch (e) {
      throw (e);
    }
  }

  Future<void> setActiveDataLinkStateNull() async {
    try {
      Map<String, String> row = {"active_data_link": "NULL"};
      await db.update(table: "state", where: "id=1", row: row);
    } catch (e) {
      throw (e);
    }
  }

  Future<void> deleteDataLink(DataLink dataLink) async {
    try {
      db.delete(table: "data_link", where: "id=${dataLink.id}");
    } catch (e) {
      throw (e);
    }
  }

  Future<void> upsertDataLink({@required DataLink dataLink}) async {
    try {
      await db.upsert(
          table: "data_link",
          indexColumn: "name",
          row: {
            "name": dataLink.name,
            "url": dataLink.url,
            "type": dataLink.typeToString(),
            "api_key": dataLink.apiKey,
            "port": dataLink.port,
            "protocol": dataLink.protocol
          },
          verbose: true);
    } catch (e) {
      throw (e);
    }
  }
}

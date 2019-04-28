import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:sqlcool/sqlcool.dart';
import "../models/data_link.dart";

class DataBase {
  final db = Db();

  Future<void> init({@required String path}) async {
    try {
      String q = """
    CREATE TABLE data_link (
    id INTEGER PRIMARY KEY,
    name VARCHAR(120) NOT NULL UNIQUE,
    url VARCHAR(255) NOT NULL,
    port INTEGER NOT NULL,
    api_key VARCHAR(255) NOT NULL,
    protocol VARCHAR(5) NOT NULL DEFAULT 'http',
    CHECK(protocol='http' OR protocol='https')
    )""";
      String q2 = """CREATE TABLE state (
    id INTEGER PRIMARY KEY,
    active_data_link INTEGER,
    upload_path VARCHAR(255),
    root_path VARCHAR(255),
    FOREIGN KEY (active_data_link) REFERENCES data_link(id)    
    )""";
      String q3 = "CREATE UNIQUE INDEX idx_data_link ON data_link (name)";
      String q4 = """INSERT INTO state VALUES(1, NULL, NULL, NULL)""";
      await db.init(path: path, queries: [q, q2, q3, q4], verbose: true);
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
    Map<String, String> result = {"root_path": null, "upload_path": null};
    try {
      List<Map<String, dynamic>> res = await db.select(
          table: "state", where: "id=1", columns: "upload_path,root_path");
      if (res[0]["upload_path"].toString() != "null")
        result["upload_path"] = res[0]["upload_path"].toString();
      if (res[0]["root_path"].toString() != "null")
        result["root_path"] = res[0]["root_path"].toString();
    } catch (e) {
      throw (e);
    }
    return result;
  }

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

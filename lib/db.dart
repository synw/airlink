import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:sqlcool/sqlcool.dart';
import "models/data_link.dart";

class DataBase {
  final db = Db();

  List<DbTable> schema() {
    DbTable dataLink = DbTable("data_link")
      ..varchar("name", unique: true)
      ..varchar("url")
      ..integer("port", defaultValue: 8084)
      ..varchar("api_key")
      ..varchar("protocol", check: 'protocol="http" OR protocol="https"')
      ..varchar("type", check: 'type="device" OR type="server"')
      ..index("name");
    DbTable state = DbTable("state")
      ..varchar("root_path", nullable: true)
      ..varchar("server_name", nullable: true)
      ..varchar("local_path", defaultValue: '/')
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

  Future<DataLink> getActiveDataLink() async {
    DataLink dl;
    List<Map<String, dynamic>> res;
    try {
      res = await db.join(
          table: "state",
          where: 'state.id=1',
          joinTable: "data_link",
          columns: "data_link.name as name,data_link.url as url," +
              "data_link.id as id, data_link.port as port, " +
              "data_link.api_key as api_key, data_link.protocol as " +
              "protocol, data_link.type as type",
          joinOn: "data_link.id=active_data_link",
          verbose: true);
    } catch (e) {
      throw ("Can not select active datalink $e");
    }
    try {
      if (res.isEmpty) return null;
      dl = DataLink.fromJson(res[0]);
    } catch (e) {
      throw ("Can not create datalink $e");
    }
    return dl;
  }

  Future<List<DataLink>> getDataLinks() async {
    var result = await db.select(table: "data_link", verbose: true);
    var dataLinks = <DataLink>[];
    result.forEach((Map<String, dynamic> item) {
      dataLinks.add(DataLink.fromJson(item));
    });
    return dataLinks;
  }

  Future<int> getActiveDataLinkId(String name) async {
    int id;
    try {
      List<Map<String, dynamic>> adl = await db.select(
          table: "data_link", columns: "id", where: 'name="$name"');
      id = int.tryParse(adl[0]["id"].toString());
    } catch (e) {
      throw (e);
    }
    return id;
  }

  /*Future<void> updateActiveDataLinkState({DataLink dataLink}) async {
    Map<String, String> row = {};
    List<Map<String, dynamic>> adl = await db.select(
        table: "data_link", columns: "id", where: 'name="${dataLink.name}"');
    if (adl.isEmpty) throw ("Can not find active data link ${dataLink.name}");
    row["active_data_link"] = adl[0]["id"].toString();
    try {
      int updated = await db.update(table: "state", where: "id=1", row: row);
      print("DB ACTIVE DATA LINK UPDATED: $updated");
    } catch (e) {
      throw (e);
    }
  }*/

  /*Future<void> setActiveDataLinkStateNull() async {
    try {
      Map<String, String> row = {"active_data_link": "NULL"};
      await db.update(table: "state", where: "id=1", row: row, verbose: true);
    } catch (e) {
      throw (e);
    }
  }*/

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

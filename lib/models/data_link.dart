import 'package:flutter/foundation.dart';

enum DataLinkType { server, device }

class DataLink {
  DataLink(
      {this.id,
      @required this.name,
      @required this.url,
      this.port = "8084",
      @required this.apiKey,
      @required this.protocol,
      this.type = DataLinkType.device});

  final int id;
  final String name;
  final String url;
  final String port;
  final String apiKey;
  final String protocol;
  DataLinkType type;

  String get address => _getAddress();

  DataLink.fromJson(dynamic data)
      : this.name = data["name"].toString(),
        this.url = data["url"].toString(),
        this.id = int.tryParse(data["id"].toString()),
        this.port = data["port"].toString(),
        this.apiKey = data["api_key"].toString(),
        this.protocol = data["protocol"].toString() {
    type = _getTypeFromString(data["type"].toString());
  }

  String _getAddress() {
    return "$protocol://$url:$port";
  }

  @override
  String toString() {
    return "$id $name : $address / $apiKey";
  }

  String typeToString() {
    String str;
    switch (this.type) {
      case DataLinkType.server:
        str = "server";
        break;
      default:
        str = "device";
    }
    return str;
  }

  DataLinkType _getTypeFromString(String strType) {
    DataLinkType t;
    switch (strType) {
      case "server":
        t = DataLinkType.server;
        break;
      default:
        t = DataLinkType.device;
    }
    return t;
  }
}

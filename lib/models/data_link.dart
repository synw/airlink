import 'package:flutter/foundation.dart';

class DataLink {
  DataLink(
      {this.id,
      @required this.name,
      @required this.url,
      @required this.port,
      @required this.apiKey,
      @required this.protocol});

  int id;
  final String name;
  final String url;
  final String port;
  final String apiKey;
  String protocol;

  String get address => _getAddress();

  DataLink.fromJson(Map<String, dynamic> data)
      : this.name = data["name"].toString(),
        this.url = data["url"].toString(),
        this.port = data["port"].toString(),
        this.apiKey = data["api_key"].toString(),
        this.protocol = data["protocol"].toString() {
    if (data.containsKey("id")) this.id = int.parse(data["id"].toString());
  }

  String _getAddress() {
    return "$protocol://$url:$port";
  }

  @override
  String toString() {
    return "$id $name : $address / $apiKey";
  }
}

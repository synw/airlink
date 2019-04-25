import 'dart:convert';
import 'package:qrcode_reader/qrcode_reader.dart';
import '../../models/data_link.dart';

Future<DataLink> scanDataLinkConfig() async {
  DataLink dl;
  await QRCodeReader().scan().then((dataString) {
    dynamic data = json.decode(dataString);
    dl = DataLink(
        name: data["name"].toString(),
        url: data["url"].toString(),
        port: data["port"].toString(),
        protocol: data["protocol"].toString(),
        apiKey: data["apiKey"].toString());
  });
  return dl;
}

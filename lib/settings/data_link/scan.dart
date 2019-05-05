import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:qrcode_reader/qrcode_reader.dart';
import 'package:audioplayer/audioplayer.dart';
import '../../models/data_link.dart';
import '../../conf.dart';

AudioPlayer audioPlayer = AudioPlayer();

Future<DataLink> scanDataLinkConfig() async {
  DataLink dl;
  await QRCodeReader().scan().then((dataString) {
    //print("SCANNED $dataString");
    playBeep();
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

Future playBeep() async {
  final dir = documentsDirectory;
  final file = new File("${dir.path}/beep.mp3");
  if (!(await file.exists())) {
    final soundData = await rootBundle.load("assets/beep.mp3");
    final bytes = soundData.buffer.asUint8List();
    await file.writeAsBytes(bytes, flush: true);
  } else {
    throw ("Mp3 file not found");
  }
  await audioPlayer
      .play(file.path, isLocal: true)
      .then((_) => audioPlayer.stop());
}

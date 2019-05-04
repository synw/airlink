import 'dart:convert';
import 'package:qrcode_reader/qrcode_reader.dart';
import 'package:audioplayer/audioplayer.dart';
import '../../models/data_link.dart';
import '../../conf.dart';

Future<DataLink> scanDataLinkConfig() async {
  AudioPlayer audioPlayer = AudioPlayer();
  DataLink dl;

  await QRCodeReader().scan().then((dataString) {
    audioPlayer
        .play(documentsDirectory.path + "/beep.mp3")
        .then((_) => audioPlayer.stop());
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

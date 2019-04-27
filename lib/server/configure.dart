import "dart:convert";
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:wifi/wifi.dart';
import 'package:uuid/uuid.dart';
import 'package:device_info/device_info.dart';
import 'package:folder_picker/folder_picker.dart';
import '../log.dart';
import '../conf.dart';
import '../models/data_link.dart';

class _ConfigureServerPageState extends State<ConfigureServerPage> {
  String ip;
  String apiKey;
  String name;
  QrImage qrCode;
  bool ready = false;

  Directory _rootDirectory;
  Directory _uploadDirectory;

  Future<void> init() async {
    ip = await Wifi.ip;
    var uuid = Uuid();
    apiKey = uuid.v1();
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    name = androidInfo.model;
    Map<String, String> dataMap = {
      "name": name,
      "url": ip,
      "api_key": apiKey,
      "protocol": "http",
      "port": "8084"
    };
    String data = const JsonEncoder.withIndent("").convert(dataMap);
    qrCode = QrImage(
      size: 250.0,
      version: 8,
      data: data,
      onError: (dynamic e) =>
          log.errorScreen("Can not generate qr code $e", context: context),
    );
  }

  void toggleServer(BuildContext context, bool start) {
    if (!fileServer.isInitialized) {
      if (_rootDirectory == null) {
        log.errorScreen('Set the root directory before starting the server',
            context: context);
        return;
      }
      if (_uploadDirectory == null) {
        log.errorScreen('Set the upload directory before starting the server',
            context: context);
        return;
      }
      fileServer.init(
          uploadDirectory: _uploadDirectory,
          rootDirectory: _rootDirectory,
          dataLink: DataLink(
              name: name,
              url: ip,
              apiKey: apiKey,
              protocol: "http",
              port: "8084"));
    }
    if (start) {
      fileServer.start();
      log.infoFlash("Server started");
    } else {
      fileServer.stop();
      log.infoFlash("Server stopped");
    }
  }

  @override
  void initState() {
    init().then((_) => setState(() => ready = true));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("Server")),
        body: SingleChildScrollView(
          child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: ready
                  ? Column(children: <Widget>[
                      const Padding(
                          padding: const EdgeInsets.only(bottom: 15.0)),
                      Container(
                          decoration: BoxDecoration(color: Colors.white),
                          child: qrCode),
                      const Padding(
                          padding: const EdgeInsets.only(bottom: 20.0)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Switch(
                            value: false,
                            onChanged: (v) => toggleServer(context, v),
                          ),
                          const Text(" Serve files"),
                        ],
                      ),
                      const Padding(
                          padding: const EdgeInsets.only(bottom: 15.0)),
                      RaisedButton(
                          child: Row(
                            children: <Widget>[
                              const Icon(Icons.file_download),
                              const Text(" Set root directory")
                            ],
                          ),
                          onPressed: () => Navigator.of(context)
                                  .push<FolderPicker>(MaterialPageRoute(
                                      builder: (BuildContext context) {
                                return FolderPicker(
                                    rootDirectory: externalDirectory,
                                    action: (BuildContext context,
                                        Directory folder) {
                                      print("PICKED FOLDER $folder");
                                      _rootDirectory = folder;
                                    });
                              }))),
                      RaisedButton(
                          child: Row(
                            children: <Widget>[
                              const Icon(Icons.file_download),
                              const Text(" Set upload directory")
                            ],
                          ),
                          onPressed: () => Navigator.of(context)
                                  .push<FolderPicker>(MaterialPageRoute(
                                      builder: (BuildContext context) {
                                return FolderPicker(
                                    rootDirectory: externalDirectory,
                                    action: (BuildContext context,
                                        Directory folder) {
                                      print("PICKED FOLDER $folder");
                                      _uploadDirectory = folder;
                                    });
                              })))
                    ])
                  : Center(child: const CircularProgressIndicator())),
        ));
  }
}

class ConfigureServerPage extends StatefulWidget {
  @override
  _ConfigureServerPageState createState() => _ConfigureServerPageState();
}

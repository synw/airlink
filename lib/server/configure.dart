import "dart:convert";
import 'dart:io';
import 'dart:async';
import 'package:path/path.dart';
import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:wifi/wifi.dart';
import 'package:uuid/uuid.dart';
import 'package:device_info/device_info.dart';
import 'package:folder_picker/folder_picker.dart';
import '../log.dart';
import '../state.dart';
import '../conf.dart';
import '../models/data_link.dart';

class _ConfigureServerPageState extends State<ConfigureServerPage> {
  String ip;
  String apiKey;
  String name;
  QrImage qrCode;

  @override
  void initState() {
    print("STATE CONF ${state.serverIsConfigured}");
    if (state.serverIsConfigured) generateQrCode().then((_) => setState(() {}));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ScopedModel<AppState>(
        model: state,
        child: Scaffold(
            appBar: AppBar(title: const Text("Server")),
            body: SingleChildScrollView(
              child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(children: <Widget>[
                    const Padding(padding: const EdgeInsets.only(bottom: 15.0)),
                    state.serverIsConfigured
                        ? Column(
                            children: <Widget>[
                              Container(
                                  decoration:
                                      BoxDecoration(color: Colors.white),
                                  child: (qrCode != null)
                                      ? qrCode
                                      : const Text("")),
                              const Padding(
                                  padding: const EdgeInsets.only(bottom: 20.0)),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Switch(
                                    value: state.fileServer.isRunning,
                                    onChanged: (v) => toggleServer(context, v)
                                        .then((_) => setState(() {})),
                                  ),
                                  const Text(" Serve files"),
                                ],
                              )
                            ],
                          )
                        : const Text(""),
                    const Padding(padding: const EdgeInsets.only(bottom: 15.0)),
                    buildPicker(
                        context: context, folderToPick: FolderToPick.root),
                    const Padding(padding: const EdgeInsets.only(bottom: 15.0)),
                    buildPicker(
                        context: context, folderToPick: FolderToPick.upload)
                  ])),
            )));
  }

  Widget buildPicker({BuildContext context, FolderToPick folderToPick}) {
    var w = <Widget>[];
    if (folderToPick == FolderToPick.root) {
      w = [
        const Icon(Icons.file_download),
        (state.serverRootDirectory != null)
            ? Text("${basename(state.serverRootDirectory.path)}")
            : const Text(" Set root directory")
      ];
    } else {
      w = [
        const Icon(Icons.file_upload),
        (state.serverUploadDirectory != null)
            ? Text("${basename(state.serverUploadDirectory.path)}")
            : const Text(" Set upload directory")
      ];
    }
    return FlatButton(
        child: Row(
          children: w,
        ),
        onPressed: () {
          Navigator.of(context).push<FolderPicker>(
              MaterialPageRoute(builder: (BuildContext context) {
            return FolderPicker(
                rootDirectory: externalDirectory,
                action: (BuildContext context, Directory folder) async {
                  switch (folderToPick) {
                    case FolderToPick.root:
                      await state.setServerRootDirectory(folder);
                      break;
                    case FolderToPick.upload:
                      await state.setServerUploadDirectory(folder);
                      break;
                  }
                  state.checkServerConfig();
                  if (state.serverIsConfigured)
                    generateQrCode().then((_) => setState(() {}));
                });
          }));
        });
  }

  Future<void> generateQrCode() async {
    ip = await Wifi.ip;
    var uuid = Uuid();
    apiKey = uuid.v1();
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    name = androidInfo.model;
    Map<String, String> dataMap = {
      "name": name,
      "url": ip,
      "apiKey": apiKey,
      "protocol": "http",
      "port": "8084"
    };
    String data = const JsonEncoder.withIndent("").convert(dataMap);
    qrCode = QrImage(
      size: 250.0,
      version: 8,
      data: data,
      onError: (dynamic e) => log.error("Can not generate qr code $e"),
    );
  }

  Future<void> toggleServer(BuildContext context, bool start) async {
    assert(state.serverIsConfigured);
    if (!state.fileServer.isInitialized) {
      state.fileServer.init(
          uploadDirectory: state.serverUploadDirectory,
          rootDirectory: state.serverRootDirectory,
          dataLink: DataLink(
              name: name,
              url: ip,
              apiKey: apiKey,
              protocol: "http",
              port: "8084"));
      await state.fileServer.onReady;
    }
    if (start) {
      state.fileServer.start();
      log.infoFlash("Server started");
    } else {
      state.fileServer.stop();
      log.infoFlash("Server stopped");
    }
  }
}

enum FolderToPick { upload, root }

class ConfigureServerPage extends StatefulWidget {
  @override
  _ConfigureServerPageState createState() => _ConfigureServerPageState();
}

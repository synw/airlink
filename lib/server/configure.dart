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
  QrImage qrCode;

  @override
  void initState() {
    Wifi.ip.then((ip) {
      state.serverIp = ip;
      print("STATE CONF ${state.serverIsConfigured}");
      if (state.serverIsConfigured)
        generateQrCode().then((_) => setState(() {}));
      else
        setServerConfig();
    });
    super.initState();
  }

  Future<void> setServerConfig() async {
    if (state.serverApiKey == null) state.setServerApiKey(Uuid().v1());
    if (state.serverName == null) {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      state.setServerName(androidInfo.model);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScopedModel<AppState>(
        model: state,
        child: Scaffold(
            appBar: AppBar(
              title: const Text("Server"),
              actions: <Widget>[
                (state.serverIsConfigured && state.fileServer.isRunning)
                    ? IconButton(
                        onPressed: () =>
                            Navigator.of(context).pushNamed("/logs"),
                        icon: const Icon(Icons.sms_failed),
                      )
                    : const Text("")
              ],
            ),
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(children: <Widget>[
                  const Padding(padding: const EdgeInsets.only(bottom: 15.0)),
                  state.serverIsConfigured
                      ? Column(
                          children: <Widget>[
                            Container(
                                width: 320.0,
                                height: 300.0,
                                decoration: BoxDecoration(color: Colors.white),
                                child:
                                    (qrCode != null) ? qrCode : const Text("")),
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
                      context: context, folderToPick: FolderToPick.upload),
                  state.serverIsConfigured
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Padding(
                                padding: const EdgeInsets.only(bottom: 15.0)),
                            Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  const Text("Info", textScaleFactor: 1.8)
                                ]),
                            const Padding(
                                padding: const EdgeInsets.only(bottom: 10.0)),
                            FlatButton(
                              child: Text("Name: ${state.serverName}"),
                              onPressed: () => editServerParamDialog(
                                  context, ServerConfigParam.name),
                            ),
                            const Padding(
                                padding: const EdgeInsets.only(bottom: 10.0)),
                            FlatButton(
                              child: Text("Api key: ${state.serverApiKey}"),
                              onPressed: () => editServerParamDialog(
                                  context, ServerConfigParam.apiKey),
                            ),
                            const Padding(
                                padding: const EdgeInsets.only(bottom: 10.0)),
                            FlatButton(
                              child: Text("Url: http://${state.serverIp}:8084"),
                              onPressed: () => null,
                            ),
                          ],
                        )
                      : const Text("")
                ]),
              ),
            )));
  }

  Widget buildPicker({BuildContext context, FolderToPick folderToPick}) {
    var w = <Widget>[];
    if (folderToPick == FolderToPick.root) {
      w = [
        const Icon(Icons.file_download),
        (state.rootDirectory != null)
            ? Text("${basename(state.rootDirectory.path)}")
            : const Text(" Set root directory")
      ];
    } else {
      w = [
        const Icon(Icons.file_upload),
        (state.uploadDirectory != null)
            ? Text("${basename(state.uploadDirectory.path)}")
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
    Map<String, String> dataMap = {
      "name": state.serverName,
      "url": state.serverIp,
      "apiKey": state.serverApiKey,
      "protocol": "http",
      "port": "8084"
    };
    String data = const JsonEncoder.withIndent("").convert(dataMap);
    qrCode = QrImage(
      size: 320.0,
      version: 8,
      data: data,
      onError: (dynamic e) => log.error("Can not generate qr code $e"),
    );
  }

  Future<void> toggleServer(BuildContext context, bool start) async {
    assert(state.serverIsConfigured);
    if (!state.fileServer.isInitialized) {
      state.fileServer.init(
          uploadDirectory: state.uploadDirectory,
          rootDirectory: state.rootDirectory,
          dataLink: DataLink(
              name: state.serverName,
              url: state.serverIp,
              apiKey: state.serverApiKey,
              protocol: "http",
              port: "8084"));
    }
    await state.fileServer.onReady;
    switch (start) {
      case true:
        state.fileServer.start(context).then((ok) {
          if (ok) {
            log.infoFlash("Server started");
          } else
            log.errorScreen("Can not start server", context: context);
        });
        break;
      case false:
        state.fileServer.stop(context).then((ok) {
          if (ok) {
            log.infoFlash("Server stoped");
          } else
            log.errorScreen("Can not stop server", context: context);
        });
    }
  }

  void editServerParamDialog(BuildContext context, ServerConfigParam param) {
    final nameController = TextEditingController();
    String paramStr;
    switch (param) {
      case ServerConfigParam.name:
        paramStr = "Name";
        break;
      case ServerConfigParam.apiKey:
        paramStr = "Api key";
        break;
      default:
        return;
    }
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(paramStr),
          actions: <Widget>[
            FlatButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
            FlatButton(
              child: const Text("Save"),
              onPressed: () {
                switch (param) {
                  case ServerConfigParam.name:
                    state
                        .setServerName(nameController.text)
                        .then((_) => generateQrCode())
                        .then((_) => setState(() {}));
                    break;
                  case ServerConfigParam.apiKey:
                    state
                        .setServerApiKey(nameController.text)
                        .then((_) => generateQrCode())
                        .then((_) => setState(() {}));
                }
                Navigator.of(context).pop(true);
              },
            ),
          ],
          content: TextField(
            controller: nameController,
            autofocus: true,
          ),
        );
      },
    );
  }
}

enum ServerConfigParam { name, apiKey }

enum FolderToPick { upload, root }

class ConfigureServerPage extends StatefulWidget {
  @override
  _ConfigureServerPageState createState() => _ConfigureServerPageState();
}

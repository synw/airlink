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

  Future<void> initServer() async {
    String ip;
    try {
      ip = await Wifi.ip;
    } catch (e) {
      log.errorFlash("Can not get device's ip address. Please check the " +
          "internet the connection");
      log.error("$e");
      return;
    }
    if (ip == null) {
      log.errorFlash("Can not get device's ip address. Please check the " +
          "internet the connection");
      return;
    }
    state.serverIp = ip;
    await initServerConfig();
    state.store.describe();
    state.checkServerConfig();
    print("-----------");
    state.store.describe();
    print("Server is configured: ${state.serverIsConfigured}");
    if (state.serverIsConfigured) generateQrCode().then((_) => setState(() {}));
  }

  @override
  void initState() {
    initServer();
    super.initState();
  }

  Future<void> initServerConfig() async {
    log.debug("NAME: ${state.serverName} ${state.serverName.runtimeType}");
    log.debug("API KEY: ${state.serverApiKey}");
    state.serverApiKey = state.serverApiKey ?? Uuid().v1();
    if (state.serverName == null) {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      state.serverName = androidInfo.model;
    }
    log.debug("NAME: ${state.serverName}");
    log.debug("API KEY: ${state.serverApiKey}");
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
                  Column(
                    children: <Widget>[
                      state.serverIsConfigured
                          ? Container(
                              width: 320.0,
                              height: 300.0,
                              decoration: BoxDecoration(color: Colors.white),
                              child: (qrCode != null) ? qrCode : const Text(""))
                          : const Text(""),
                      const Padding(
                          padding: const EdgeInsets.only(bottom: 20.0)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          state.serverIsConfigured
                              ? Row(children: <Widget>[
                                  Switch(
                                    value: state.fileServer.isRunning,
                                    onChanged: (v) => toggleServer(context, v)
                                        .then((_) => setState(() {})),
                                  ),
                                  const Text(" Serve files")
                                ])
                              : const Text("Configure the shared directory"),
                          const Text(""),
                        ],
                      )
                    ],
                  ),
                  const Padding(padding: EdgeInsets.only(bottom: 15.0)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      buildPicker(context: context),
                    ],
                  ),
                  state.serverIsConfigured
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Padding(
                                padding: const EdgeInsets.only(bottom: 15.0)),
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

  Widget buildPicker({BuildContext context}) {
    var w = <Widget>[
      const Icon(Icons.file_download),
      (state.rootDirectory != null)
          ? Text("${basename(state.rootDirectory.path)}")
          : const Text(" Set the shared directory")
    ];
    return FlatButton(
        child: Row(
          children: w,
        ),
        onPressed: () {
          Navigator.of(context).push<FolderPicker>(
              MaterialPageRoute(builder: (BuildContext context) {
            return FolderPicker(
                rootDirectory: externalDirectory,
                action: (BuildContext context, Directory folder) {
                  state.rootDirectory = folder;
                  state.checkServerConfig();
                  state.store.describe();
                  if (state.serverIsConfigured)
                    generateQrCode().then((_) => setState(() {}));
                });
          }));
        });
  }

  Future<void> generateQrCode() async {
    print("GENERATING QR CODE");
    Map<String, String> dataMap = {
      "name": state.serverName,
      "url": state.serverIp,
      "api_key": state.serverApiKey,
    };
    String data = const JsonEncoder.withIndent("").convert(dataMap);
    qrCode = QrImage(
      size: 320.0,
      version: 5,
      data: data,
      onError: (dynamic e) => log.error("Can not generate qr code $e"),
    );
  }

  Future<void> toggleServer(BuildContext context, bool start) async {
    assert(state.serverIsConfigured);
    if (!state.fileServer.isInitialized) {
      state.fileServer.init(
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
                Navigator.of(context).pop();
              },
            ),
            FlatButton(
              child: const Text("Save"),
              onPressed: () {
                switch (param) {
                  case ServerConfigParam.name:
                    state.serverName = nameController.text;
                    generateQrCode().then((_) => setState(() {}));
                    break;
                  case ServerConfigParam.apiKey:
                    state.serverApiKey = nameController.text;
                    generateQrCode().then((_) => setState(() {}));
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

class ConfigureServerPage extends StatefulWidget {
  @override
  _ConfigureServerPageState createState() => _ConfigureServerPageState();
}

import 'package:flutter/material.dart';
import 'package:card_settings/card_settings.dart';
import '../../models/data_link.dart';
import '../../state.dart';
import '../../log.dart';

class _AddDataLinkManualState extends State<AddDataLinkManual> {
  _AddDataLinkManualState(
      {this.name = "",
      this.url = "",
      this.apiKey = "",
      this.port = 8084,
      this.https = false,
      this.type = DataLinkType.device,
      this.focus = true});

  bool https;
  String url;
  String name;
  String apiKey;
  int port;
  bool focus;
  DataLinkType type;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _focusNode = FocusNode();

  Future<void> save(BuildContext context) async {
    String protocol;
    https ? protocol = "http" : protocol = "http";
    DataLink dataLink = DataLink(
        name: name,
        url: url,
        apiKey: apiKey,
        protocol: protocol,
        type: type,
        port: "$port");
    // update persistant state
    try {
      await state.setActiveDataLink(context: context, dataLink: dataLink);
    } catch (e) {
      log.errorScreen("Can not update active datalink $e", context: context);
      throw (e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Configure a data link"),
        ),
        body: Form(
          key: _formKey,
          child: CardSettings(
            children: <Widget>[
              CardSettingsHeader(label: 'Data link settings'),
              CardSettingsText(
                  focusNode: _focusNode,
                  autofocus: focus,
                  initialValue: name,
                  label: 'Name',
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'The name is required.';
                  },
                  onChanged: (value) => name = value),
              CardSettingsText(
                  initialValue: url,
                  label: 'Url',
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'The url is required.';
                  },
                  onChanged: (value) => url = value),
              CardSettingsSwitch(
                  label: "Https",
                  initialValue: https,
                  onChanged: (value) => https = value),
              CardSettingsText(
                  label: 'Api key',
                  initialValue: apiKey,
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'The api key is required.';
                  },
                  onChanged: (value) => apiKey = value),
              CardSettingsInt(
                  label: "Port",
                  initialValue: port,
                  onChanged: (value) => port = value),
              CardSettingsButton(
                  label: "Save",
                  onPressed: () async {
                    await save(context).then((_) {
                      Navigator.of(context).pushReplacementNamed('/settings');
                    });
                    log.infoFlash("Data link saved");
                  })
            ],
          ),
        ));
  }
}

class AddDataLinkManual extends StatefulWidget {
  AddDataLinkManual(
      {this.name,
      this.url,
      this.apiKey,
      this.port = 8084,
      this.https = false,
      this.type = DataLinkType.device,
      this.focus = true});

  final bool https;
  final String url;
  final String name;
  final String apiKey;
  final int port;
  final bool focus;
  final DataLinkType type;

  @override
  _AddDataLinkManualState createState() => _AddDataLinkManualState(
      name: name,
      url: url,
      port: port,
      apiKey: apiKey,
      https: https,
      type: type,
      focus: focus);
}

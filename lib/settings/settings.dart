import 'package:flutter/material.dart';
import 'package:card_settings/card_settings.dart';
import 'db.dart';
import '../conf.dart';

class _SettingsPageState extends State<SettingsPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _https;
  String _rawServerUrl;
  String _apiKey;
  int _port;

  final _focusNode = FocusNode();

  bool _ready = false;

  Future<void> save(BuildContext context) async {
    try {
      await saveSettings(
          db: settingsDb,
          serverUrl: _rawServerUrl,
          port: _port,
          apiKey: _apiKey,
          https: _https);
    } catch (e) {
      log.criticalScreen("$e", context: context);
    }
    String protocol;
    _https ? protocol = "https" : protocol = "http";
    serverUrl = "$protocol://$_rawServerUrl:$_port";
    apiKey = _apiKey;
    serverConfigured = true;
  }

  @override
  void initState() {
    getSettingsValues(settingsDb).then((Map<String, dynamic> row) {
      _https = (row["https"] == true);
      _port = int.parse(row["port"].toString());
      _rawServerUrl = row["server_url"].toString();
      _apiKey = row["api_key"].toString();
      setState(() => _ready = true);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Settings"),
        ),
        body: _ready
            ? Form(
                key: _formKey,
                child: CardSettings(
                  children: <Widget>[
                    CardSettingsHeader(label: 'Server settings'),
                    CardSettingsText(
                        focusNode: _focusNode,
                        autofocus: true,
                        label: 'Server url',
                        initialValue: _rawServerUrl,
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return 'The server url is required.';
                        },
                        onChanged: (value) => _rawServerUrl = value),
                    CardSettingsSwitch(
                        label: "Https protocol",
                        initialValue: _https,
                        onChanged: (value) => _https = value),
                    CardSettingsText(
                        label: 'Api key',
                        initialValue: _apiKey ?? "",
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return 'The api key is required.';
                        },
                        onChanged: (value) => _apiKey = value),
                    CardSettingsInt(
                        label: "Port",
                        initialValue: _port,
                        onChanged: (value) => _port = value),
                    CardSettingsButton(
                        label: "Save",
                        onPressed: () {
                          save(context).then((_) {
                            Navigator.of(context).pop();
                            log.infoFlash("Settings saved");
                          });
                        })
                  ],
                ),
              )
            : Center(child: const CircularProgressIndicator()));
  }
}

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

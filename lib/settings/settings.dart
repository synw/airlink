import 'package:flutter/material.dart';
import '../conf.dart';
import '../models/data_link.dart';
import 'data_link/scan.dart';
import 'data_link/manual.dart';
import '../state.dart';

class _SettingsPageState extends State<SettingsPage> {
  @override
  void didChangeDependencies() {
    if (state.activeDataLink == null) addDataLinkDialog(context);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    Widget w;
    state.activeDataLink != null ? w = ListDataLinks() : w = const Text("");
    return Scaffold(
      appBar: AppBar(
        title: const Text("Data links"),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => addDataLinkDialog(context),
          )
        ],
      ),
      body: w,
    );
  }
}

class _ListDataLinksState extends State<ListDataLinks> {
  var dataLinks = <DataLink>[];

  Future<List<DataLink>> initDataLinks() async {
    var dl = await db.getDataLinks();
    return dl;
  }

  @override
  void initState() {
    initDataLinks().then((dl) => setState(() => dataLinks = dl));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var w = <SwitchListTile>[];
    dataLinks.forEach((dl) {
      w.add(SwitchListTile(
          value: (dl.id == state.activeDataLink.id),
          onChanged: (val) => null,
          title: Text(dl.name)));
    });
    return ListView(children: w);
  }
}

class NoDataLink extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(35.0),
        child: Center(
          child: RaisedButton(
            child: Row(
              children: <Widget>[
                const Icon(Icons.link),
                const Text(" Add a data link")
              ],
            ),
            onPressed: () => addDataLinkDialog(context),
          ),
        ));
  }
}

void addDataLinkDialog(BuildContext context) {
  showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
            title: const Text("Add a data link"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                RaisedButton(
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.scanner),
                        const Text("Scan"),
                      ],
                    ),
                    onPressed: () {
                      scanDataLinkConfig().then((DataLink dataLink) {
                        Navigator.of(context).pop();
                        Navigator.of(context).push<AddDataLinkManual>(
                            MaterialPageRoute(
                                builder: (BuildContext context) =>
                                    AddDataLinkManual(
                                      focus: false,
                                      name: dataLink.name,
                                      apiKey: dataLink.apiKey,
                                      url: dataLink.url,
                                      https: (dataLink.protocol == "https"),
                                      port: int.parse(dataLink.port),
                                    )));
                      });
                    }),
                const Padding(padding: const EdgeInsets.only(bottom: 15.0)),
                RaisedButton(
                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.edit),
                      const Text("Configure"),
                    ],
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushNamed("/add_data_link_manual");
                  },
                ),
                const Padding(padding: EdgeInsets.only(bottom: 15.0)),
              ],
            ),
            actions: <Widget>[
              FlatButton(
                child: const Text("Cancel"),
                onPressed: () => Navigator.of(context).pop(),
              )
            ],
          ));
}

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class ListDataLinks extends StatefulWidget {
  @override
  _ListDataLinksState createState() => _ListDataLinksState();
}

import 'package:flutter/material.dart';
import '../conf.dart';
import '../models/data_link.dart';
import 'data_link/scan.dart';
import 'data_link/manual.dart';
import '../state.dart';

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    Widget w;
    state.activeDataLink != null ? w = ListDataLinks() : w = AddDataLink();
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
    dataLinks.forEach((dataLink) {
      w.add(SwitchListTile(
          value: (dataLink.name == state.activeDataLink.name),
          onChanged: (val) {
            if (val)
              state
                  .setActiveDataLink(dataLink: dataLink, context: context)
                  .then((_) => setState(() {}));
            else {
              if (state.activeDataLink.name == dataLink.name)
                state.setActiveDataLinkNull().then((_) => setState(() {}));
            }
          },
          title: GestureDetector(
            child: Text(dataLink.name),
            onTap: () => deleteDataLink(context, dataLink),
          )));
    });
    return ListView(children: w);
  }

  void deleteDataLink(BuildContext context, DataLink dataLink) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Delete ${dataLink.name}?"),
          actions: <Widget>[
            FlatButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            RaisedButton(
              child: const Text("Delete"),
              color: Colors.red,
              textColor: Colors.white,
              onPressed: () async {
                Navigator.of(context).pop();
                if (state.activeDataLink.name == dataLink.name)
                  await state.setActiveDataLinkNull();
                await db.deleteDataLink(dataLink);
                setState(() {});
              },
            ),
          ],
        );
      },
    );
  }
}

class AddDataLink extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(35.0),
        child: Center(
          child: const AddDataLinkButtons(),
        ));
  }
}

void addDataLinkDialog(BuildContext context) {
  showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
            title: const Text("Add a data link"),
            content: const AddDataLinkButtons(),
            actions: <Widget>[
              FlatButton(
                child: const Text("Cancel"),
                onPressed: () => Navigator.of(context).pop(),
              )
            ],
          ));
}

class AddDataLinkButtons extends StatelessWidget {
  const AddDataLinkButtons({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
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
                Navigator.of(context)
                    .pushReplacement<SettingsPage, AddDataLinkManual>(
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
    );
  }
}

class ListDataLinks extends StatefulWidget {
  @override
  _ListDataLinksState createState() => _ListDataLinksState();
}

class SettingsPage extends StatefulWidget {
  SettingsPage({
    Key key,
  }) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

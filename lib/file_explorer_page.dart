import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'remote_file_explorer.dart';
import 'file_explorer.dart';
import 'commands.dart';
import 'state.dart';

class _FileExplorerPageState extends State<FileExplorerPage> {
  final _addDirController = TextEditingController();

  @override
  void dispose() {
    _addDirController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScopedModel<AppState>(
        model: state,
        child: Scaffold(
            appBar: AppBar(
                title: Opacity(
                    opacity: 0.3,
                    child: Image.asset('assets/logo_small.png', height: 40.0)),
                actions: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.speaker_phone, size: 20.0),
                    tooltip: 'Server',
                    onPressed: () =>
                        Navigator.of(context).pushNamed("/server_config"),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings, size: 20.0),
                    tooltip: 'Settings',
                    onPressed: () =>
                        Navigator.of(context).pushNamed("/settings"),
                  ),
                  IconButton(
                    icon: const Icon(Icons.create_new_folder),
                    tooltip: 'Add directory',
                    onPressed: () {
                      _addDir(context);
                    },
                  ),
                  state.activeDataLink != null
                      ? state.remoteViewActive
                          ? IconButton(
                              icon: const Icon(Icons.close),
                              tooltip: 'Hide remote view',
                              onPressed: () {
                                state.toggleRemoteView();
                                setState(() {});
                              })
                          : IconButton(
                              icon: const Icon(Icons.cloud_queue),
                              tooltip: 'Show remote view',
                              onPressed: () {
                                state.toggleRemoteView();
                                setState(() {});
                              })
                      : const Text("")
                ]),
            body: Container(
                child: Stack(children: <Widget>[
              MediaQuery.of(context).orientation == Orientation.portrait
                  ? Column(children: [
                      Expanded(
                          child: ScopedModelDescendant<AppState>(
                              builder: (context, child, model) =>
                                  ExplorerListing())),
                      state.remoteViewActive
                          ? const Divider(height: 25.0)
                          : const Text(""),
                      state.remoteViewActive
                          ? Container(
                              height: MediaQuery.of(context).size.height / 2.35,
                              child: ScopedModelDescendant<AppState>(
                                  builder: (context, child, model) =>
                                      RemoteFileExplorer()))
                          : const Text(""),
                    ])
                  : Row(children: [
                      Expanded(
                          child: ScopedModelDescendant<AppState>(
                              builder: (context, child, model) =>
                                  ExplorerListing())),
                      state.remoteViewActive
                          ? Expanded(
                              child: Container(
                                  height:
                                      MediaQuery.of(context).size.width / 2.0,
                                  child: ScopedModelDescendant<AppState>(
                                      builder: (context, child, model) =>
                                          RemoteFileExplorer())))
                          : const Text(""),
                    ])
            ]))));
  }

  void _addDir(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
            title: const Text("Create a directory"),
            actions: <Widget>[
              FlatButton(
                child: const Text("Cancel"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              FlatButton(
                child: const Text("Create"),
                onPressed: () {
                  createDir(_addDirController.text);
                  Navigator.of(context).pop();
                },
              ),
            ],
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  TextField(
                    controller: _addDirController,
                    autofocus: true,
                    autocorrect: false,
                  ),
                ],
              ),
            ));
      },
    );
  }
}

class FileExplorerPage extends StatefulWidget {
  FileExplorerPage();

  @override
  _FileExplorerPageState createState() => _FileExplorerPageState();
}

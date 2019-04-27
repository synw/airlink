import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:open_file/open_file.dart';
import "bloc_file_explorer.dart";
import "models/filesystem.dart";
import 'zip_upload.dart';
import 'remote_file_explorer.dart';
import 'settings/settings.dart';
import 'state.dart';

class _FileExplorerPageState extends State<FileExplorerPage> {
  _FileExplorerPageState(this.path) : assert(path != null) {
    _bloc = ItemsBloc(path);
  }

  ItemsBloc _bloc;
  final String path;

  final _addDirController = TextEditingController();
  SlidableController _slidableController;

  @override
  void dispose() {
    _addDirController.dispose();
    _bloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: Opacity(
                opacity: 0.3,
                child: Image.asset('assets/logo_small.png', height: 40.0)),
            actions: <Widget>[
              IconButton(
                icon: const Icon(Icons.folder, size: 20.0),
                tooltip: 'Dataview',
                onPressed: () {
                  Navigator.of(context).pushNamed("/dataview");
                },
              ),
              IconButton(
                icon: const Icon(Icons.speaker_phone, size: 20.0),
                tooltip: 'Server',
                onPressed: () {
                  Navigator.of(context).pushNamed("/server_config");
                },
              ),
              IconButton(
                icon: const Icon(Icons.settings, size: 20.0),
                tooltip: 'Settings',
                onPressed: () {
                  Navigator.of(context).push<SettingsPage>(MaterialPageRoute(
                      builder: (BuildContext context) => SettingsPage()));
                },
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
                          onPressed: () => setState(() =>
                              state.remoteViewActive = !state.remoteViewActive))
                      : IconButton(
                          icon: const Icon(Icons.cloud_queue),
                          tooltip: 'Show remote view',
                          onPressed: () => setState(() =>
                              state.remoteViewActive = !state.remoteViewActive))
                  : const Text("")
            ]),
        body: Container(
            child: Stack(children: <Widget>[
          Column(children: [
            Expanded(
                child: ExplorerListing(
                    path: path,
                    bloc: _bloc,
                    slidableController: _slidableController)),
            state.remoteViewActive
                ? const Divider(height: 25.0)
                : const Text(""),
            state.remoteViewActive
                ? Container(
                    height: MediaQuery.of(context).size.height / 2.35,
                    child: RemoteFileExplorer(path))
                : const Text(""),
          ])
        ])));
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
                  _bloc.createDir(_addDirController.text).then((_) {
                    Navigator.of(context).pop();
                    _bloc.lsDir();
                  });
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

class ExplorerListing extends StatelessWidget {
  const ExplorerListing({
    Key key,
    @required ItemsBloc bloc,
    @required this.path,
    @required SlidableController slidableController,
  })  : _bloc = bloc,
        _slidableController = slidableController,
        super(key: key);

  final ItemsBloc _bloc;
  final String path;
  final SlidableController _slidableController;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DirectoryItem>>(
      stream: this._bloc.items,
      builder:
          (BuildContext context, AsyncSnapshot<List<DirectoryItem>> snapshot) {
        if (snapshot.hasData) {
          return ListView.builder(
              itemCount: snapshot.data.length,
              itemBuilder: (BuildContext context, int index) {
                DirectoryItem item = snapshot.data[index];
                return Slidable(
                  key: Key(item.filename),
                  controller: _slidableController,
                  direction: Axis.horizontal,
                  delegate: const SlidableBehindDelegate(),
                  actionExtentRatio: 0.25,
                  child: _buildVerticalListItem(context, item),
                  actions: _getSlideIconActions(context, item),
                );
              });
        } else {
          return Center(child: const CircularProgressIndicator());
        }
      },
    );
  }

  Widget _buildVerticalListItem(BuildContext context, DirectoryItem item) {
    return ListTile(
      title: Text(item.filename),
      dense: true,
      leading: item.icon,
      trailing: Text("${item.filesize}"),
      onTap: () {
        String p;
        (path == "/")
            ? p = path + item.filename
            : p = path + "/" + item.filename;
        if (item.isDirectory) {
          //p = item.path;
          Navigator.of(context)
              .push(MaterialPageRoute<FileExplorerPage>(builder: (context) {
            return FileExplorerPage(p);
          }));
        } else {
          OpenFile.open(item.path);
        }
      },
    );
  }

  List<Widget> _getSlideIconActions(BuildContext context, DirectoryItem item) {
    List<Widget> ic = [];
    ic.add(IconSlideAction(
      caption: 'Delete',
      color: Colors.red,
      icon: Icons.delete,
      onTap: () => _confirmDeleteDialog(context, item),
    ));
    if (state.activeDataLink != null) {
      if (item.item is File) {
        ic.add(IconSlideAction(
          caption: 'Upload',
          color: Colors.lightBlue,
          icon: Icons.file_upload,
          onTap: () => upload(
                serverUrl: state.activeDataLink.url,
                filename: item.filename,
                file: File(item.item.path),
                context: context,
              ),
        ));
      } else if (item.item is Directory) {
        ic.add(IconSlideAction(
            caption: 'Upload',
            color: Colors.lightBlue,
            icon: Icons.file_upload,
            onTap: () {
              zipUpload(
                      directory: item,
                      serverUrl: state.activeDataLink.url,
                      context: context)
                  .catchError((dynamic e) {
                throw (e);
              });
            }));
      }
    }
    return ic;
  }

  void _confirmDeleteDialog(BuildContext context, DirectoryItem item) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Delete ${item.filename}?"),
          actions: <Widget>[
            FlatButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            FlatButton(
              child: const Text("Delete"),
              color: Colors.red,
              onPressed: () {
                _bloc.deleteItem(item).then((_) {
                  Navigator.of(context).pop();
                  _bloc.lsDir();
                });
              },
            ),
          ],
        );
      },
    );
  }
}

class FileExplorerPage extends StatefulWidget {
  FileExplorerPage(this.path);

  final String path;

  @override
  _FileExplorerPageState createState() => _FileExplorerPageState(path);
}

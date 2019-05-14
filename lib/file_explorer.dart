import 'dart:io';
import 'package:airlink/models/data_link.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:open_file/open_file.dart';
import "models/filesystem.dart";
import 'zip_upload.dart';
import 'state.dart';
import 'commands.dart';

class _ExplorerListingState extends State<ExplorerListing> {
  SlidableController _slidableController;

  @override
  void initState() {
    lsDir();
    super.initState();
  }

  List<Widget> buildList() {
    var w = <Widget>[];
    if (state.localPath != "/" && state.localPath != "")
      w.add(GestureDetector(
        child: ListTile(
          leading: const Icon(Icons.arrow_upward),
          title: const Text("..", textScaleFactor: 1.5),
        ),
        onTap: () {
          var li = state.localPath.split("/");
          li.removeLast();
          state.localPath = li.join("/");
          lsDir();
        },
      ));
    for (var item in state.directoryItems) {
      w.add(Slidable(
        key: Key(item.filename),
        controller: _slidableController,
        direction: Axis.horizontal,
        delegate: const SlidableBehindDelegate(),
        actionExtentRatio: 0.25,
        child: _buildVerticalListItem(context, item),
        actions: _getSlideIconActions(context, item),
      ));
    }
    return w;
  }

  @override
  Widget build(BuildContext context) {
    Widget w;
    (state.directoryItems == null)
        ? w = Center(child: const CircularProgressIndicator())
        : w = ListView(children: buildList());
    return w;
  }

  Widget _buildVerticalListItem(BuildContext context, DirectoryItem item) {
    return ListTile(
      title: Text(item.filename),
      dense: true,
      leading: item.icon,
      trailing: Text("${item.filesize}"),
      onTap: () {
        if (item.isDirectory) {
          String p;
          (state.localPath == "/")
              ? p = state.localPath + item.filename
              : p = state.localPath + "/" + item.filename;
          state.localPath = p;
          lsDir();
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
    if (state.activeDataLink != null &&
        state.activeDataLink.type == DataLinkType.server) {
      if (item.item is File) {
        ic.add(IconSlideAction(
          caption: 'Upload',
          color: Colors.lightBlue,
          icon: Icons.file_upload,
          onTap: () => upload(
                serverUrl: state.activeDataLink.address,
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
                      serverUrl: state.activeDataLink.address,
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
                deleteItem(item).then((_) {
                  Navigator.of(context).pop();
                });
              },
            ),
          ],
        );
      },
    );
  }
}

class ExplorerListing extends StatefulWidget {
  ExplorerListing({
    Key key,
  }) : super(key: key);

  @override
  _ExplorerListingState createState() => _ExplorerListingState();
}

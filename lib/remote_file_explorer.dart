import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:filesize/filesize.dart';
import 'package:dio/dio.dart';
import 'models/filesystem.dart';
import 'file_icons.dart';
import 'downloader.dart';
import 'file_explorer.dart';
import 'state.dart';
import 'log.dart';

class _RemoteFileExplorerState extends State<RemoteFileExplorer> {
  _RemoteFileExplorerState(this.path);

  final String path;

  RemoteDirectoryListing listing;

  SlidableController _slidableController;

  Future<void> getData() async {
    assert(state.activeDataLink != null);
    print("GET ${state.activeDataLink.address}");
    print("GET ${state.httpClient}");
    try {
      var response = await state.httpClient.post<Map<String, dynamic>>(
          "${state.activeDataLink.address}/ls",
          data: <String, dynamic>{"path": state.remotePath});
      setState(() => listing = RemoteDirectoryListing.fromJson(response.data));
    } on DioError catch (e) {
      setState(() {
        state.remoteViewActive = false;
        Navigator.of(context)
            .pushReplacement<RemoteFileExplorer, FileExplorerPage>(
                MaterialPageRoute(
                    builder: (BuildContext context) => FileExplorerPage(path)));
        String msg = "Can not connect to server: $e";
        log.errorScreen(msg, context: context);
      });
      return false;
    } catch (e) {
      setState(() {
        state.remoteViewActive = false;
        Navigator.of(context)
            .pushReplacement<RemoteFileExplorer, FileExplorerPage>(
                MaterialPageRoute(
                    builder: (BuildContext context) => FileExplorerPage(path)));
        String msg = "Can not connect to server: $e";
        log.errorScreen(msg, context: context);
      });
      return false;
    }
  }

  @override
  void initState() {
    getData();
    super.initState();
  }

  List<Widget> buildListing(RemoteDirectoryListing listing) {
    var w = <Widget>[];
    if (state.remotePath != "/" && state.remotePath != "")
      w.add(GestureDetector(
        child: ListTile(
          leading: const Icon(Icons.arrow_upward),
          title: const Text("..", textScaleFactor: 1.5),
        ),
        onTap: () {
          var li = state.remotePath.split("/");
          li.removeLast();
          state.remotePath = li.join("/");
          getData();
        },
      ));
    for (var dir in listing.directories) {
      w.add(GestureDetector(
        child: ListTile(
            dense: true,
            leading: const Icon(Icons.folder, color: Colors.orange),
            title: Text(dir.name)),
        onTap: () {
          (state.remotePath != "/")
              ? state.remotePath = state.remotePath + "/" + dir.name
              : state.remotePath = state.remotePath + dir.name;
          getData();
        },
      ));
    }
    for (var file in listing.files) {
      w.add(Slidable(
        key: Key(file.name),
        controller: _slidableController,
        direction: Axis.horizontal,
        delegate: const SlidableBehindDelegate(),
        actionExtentRatio: 0.25,
        child: ListTile(
            dense: true,
            trailing: Text(filesize(file.size)),
            leading: setFileIcon(file.name),
            title: Text(file.name)),
        actions: [
          IconSlideAction(
            caption: 'Download',
            color: Colors.blue,
            icon: Icons.file_download,
            onTap: () {
              log.infoFlash("Downloading file");
              String path;
              (state.remotePath == "/") ? path = "" : path = state.remotePath;
              String url =
                  state.activeDataLink.address + path + "/" + file.name;
              print("Downloading $url");
              var dl = Downloader();
              dl.download(url, path);
              dl.completedController.listen((_) {
                dl.dispose();
                try {
                  Navigator.of(context)
                      .pushReplacement<RemoteFileExplorer, FileExplorerPage>(
                          MaterialPageRoute(
                              builder: (BuildContext context) =>
                                  FileExplorerPage(path)));
                } catch (_) {}
                log.infoFlash("Download completed");
              });
            },
          )
        ],
      ));
    }
    return w;
  }

  @override
  Widget build(BuildContext context) {
    Widget w;
    (listing != null)
        ? w = ListView(children: buildListing(listing))
        : w = Center(child: const CircularProgressIndicator());
    return w;
  }
}

class RemoteFileExplorer extends StatefulWidget {
  RemoteFileExplorer(this.path);

  final String path;

  @override
  _RemoteFileExplorerState createState() => _RemoteFileExplorerState(path);
}

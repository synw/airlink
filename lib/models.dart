import 'dart:io';
import 'package:path/path.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:filesize/filesize.dart' as fs;
import 'file_icons.dart';

class ListedDirectory {
  ListedDirectory(
      {@required this.directory,
      @required this.listedDirectories,
      @required this.listedFiles}) {
    _getItems();
  }

  final Directory directory;
  final List<Directory> listedDirectories;
  final List<File> listedFiles;

  List<DirectoryItem> _items;

  List<DirectoryItem> get items => _items;

  void _getItems() {
    var _d = <DirectoryItem>[];
    for (var _item in listedDirectories) {
      _d.add(DirectoryItem(item: _item));
    }
    var _f = <DirectoryItem>[];
    for (var _item in listedFiles) {
      _f.add(DirectoryItem(item: _item));
    }
    _items = new List.from(_d)..addAll(_f);
  }
}

class DirectoryItem {
  DirectoryItem({@required this.item}) {
    _filesize = _getFilesize(item);
    _filename = basename(item.path);
    _icon = _setIcon(item, _filename);
  }

  final FileSystemEntity item;

  String _filename;
  Icon _icon;
  String _filesize = "";

  Icon get icon => _icon;
  String get filesize => _filesize;
  String get filename => _filename;
  bool get isDirectory => item is Directory;
  String get path => item.path;
  Directory get parent => item.parent;

  String _getFilesize(FileSystemEntity _item) {
    if (_item is File) {
      String size = fs.filesize(_item.lengthSync());
      return "$size";
    } else {
      return "";
    }
  }

  Icon _setIcon(dynamic _item, String _filename) {
    if (_item is Directory)
      return const Icon(Icons.folder, color: Colors.yellow);
    return setFileIcon(_filename);
  }
}

class RemoteDirectoryListing {
  String path;
  List<RemoteDirectory> directories;
  List<RemoteFile> files;

  RemoteDirectoryListing.fromJson(Map<String, dynamic> data) {
    var dirs = <RemoteDirectory>[];
    var files = <RemoteFile>[];
    for (var item in data["files"]) {
      files.add(RemoteFile(
          name: item["name"].toString(),
          size: int.parse(item["size"].toString())));
    }
    for (var item in data["directories"]) {
      dirs.add(RemoteDirectory(name: item["name"].toString()));
    }
    this.directories = dirs;
    this.files = files;
  }
}

class RemoteDirectory {
  const RemoteDirectory({this.name});

  final String name;
}

class RemoteFile {
  const RemoteFile({this.name, this.size});

  final String name;
  final int size;
}

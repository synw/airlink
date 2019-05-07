import 'dart:io';
import 'dart:async';
import "models/filesystem.dart";
import 'conf.dart';
import 'state.dart';

Future<void> deleteItem(DirectoryItem item) async {
  try {
    await _rm(item);
    lsDir();
  } catch (e) {
    throw ("Can not delete directory: $e.message");
  }
}

Future<void> createDir(String name) async {
  try {
    // trim the filename for leading and trailing spaces
    name = name.trim();
    // create the directory
    await _mkdir(Directory(externalDirectory.path + state.localPath), name);
    lsDir();
  } catch (e) {
    throw ("Can not create directory: $e.message");
  }
}

Future<void> lsDir() async {
  var items = <DirectoryItem>[];
  try {
    ListedDirectory d = await _getListedDirectory(
        Directory(externalDirectory.path + state.localPath));
    items = d.items;
  } catch (e) {
    throw ("Can not ls dir: $e.message");
  }
  state.setDirectoryListing(items);
}

Future<void> _rm(DirectoryItem item) async {
  try {
    item.item.deleteSync(recursive: true);
  } catch (e) {
    throw ("Error deleting the file: $e");
  }
}

Future<void> _mkdir(Directory currentDir, String name) async {
  try {
    Directory dir = Directory(currentDir.path + "/$name");
    dir.createSync(recursive: true);
  } catch (e) {
    throw ("Can not create directory: $e");
  }
}

Future<ListedDirectory> _getListedDirectory(Directory dir) async {
  List contents = dir.listSync()..sort((a, b) => a.path.compareTo(b.path));
  var dirs = <Directory>[];
  var files = <File>[];
  for (var fileOrDir in contents) {
    if (fileOrDir is Directory) {
      var dir = Directory("${fileOrDir.path}");
      dirs.add(dir);
    } else {
      var file = File("${fileOrDir.path}");
      files.add(file);
    }
  }
  return ListedDirectory(
      directory: dir, listedDirectories: dirs, listedFiles: files);
}

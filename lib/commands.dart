import 'dart:io';
import 'dart:async';
import 'package:pedantic/pedantic.dart';
import "models/filesystem.dart";
import 'conf.dart';
import 'state.dart';
import 'log.dart';

Future<void> deleteItem(DirectoryItem item) async {
  try {
    await _rm(item);
    await lsDir();
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
    await lsDir();
  } catch (e) {
    throw ("Can not create directory: $e.message");
  }
}

Future<void> lsDir() async {
  var items = <DirectoryItem>[];
  try {
    var path = externalDirectory.path;
    path = path.replaceAll("/Android/data/com.example.airlink/files", "");
    path += state.localPath;
    unawaited(log.debug("LS $path"));
    final d = await _getListedDirectory(Directory(path));
    items = d.items;
  } catch (e) {
    throw ("Can not ls dir: $e");
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
    Directory(currentDir.path + "/$name")..createSync(recursive: true);
  } catch (e) {
    throw ("Can not create directory: $e");
  }
}

Future<ListedDirectory> _getListedDirectory(Directory dir) async {
  final contents = dir.listSync()..sort((a, b) => a.path.compareTo(b.path));
  final dirs = <Directory>[];
  final files = <File>[];
  for (var fileOrDir in contents) {
    if (fileOrDir is Directory) {
      final dir = Directory("${fileOrDir.path}");
      dirs.add(dir);
    } else {
      final file = File("${fileOrDir.path}");
      files.add(file);
    }
  }
  return ListedDirectory(
      directory: dir, listedDirectories: dirs, listedFiles: files);
}

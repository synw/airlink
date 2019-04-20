import 'dart:io';
import 'dart:async';
import "models.dart";

Future<void> rm(DirectoryItem item) async {
  try {
    item.item.deleteSync(recursive: true);
  } catch (e) {
    throw ("Error deleting the file: $e");
  }
}

Future<void> mkdir(Directory currentDir, String name) async {
  try {
    Directory dir = Directory(currentDir.path + "/$name");
    dir.createSync(recursive: true);
  } catch (e) {
    throw ("Can not create directory: $e");
  }
}

Future<ListedDirectory> getListedDirectory(Directory dir) async {
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

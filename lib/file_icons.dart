import 'package:flutter/material.dart';

Icon setFileIcon(String filename) {
  String extension = filename.split(".").last;
  if (extension == "db" || extension == "sqlite" || extension == "sqlite3") {
    return const Icon(Icons.dns);
  } else if (extension == "jpg" || extension == "jpeg" || extension == "png") {
    return const Icon(Icons.image);
  }
  // default
  return const Icon(Icons.description, color: Colors.grey);
}

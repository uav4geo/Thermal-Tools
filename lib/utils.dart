import 'dart:io';

Future<bool> checkIfDirectory(String path) async {
  return await FileSystemEntity.isDirectory(path);
}

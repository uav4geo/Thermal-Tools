import 'dart:io';
import 'package:path/path.dart' as p;

Future<bool> checkIfDirectory(String path) async {
  return await FileSystemEntity.isDirectory(path);
}

Future<void> saveLog(String path, String log) async {
  File f = File(p.join(path, "log.txt"));
  await f.writeAsString(log);
}

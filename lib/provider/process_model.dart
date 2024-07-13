import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

var processModel = ChangeNotifierProvider((ref) => ProcessModel());

class ProcessModel extends ChangeNotifier {
  final List<String> _processes = [];

  List<String> get processes => _processes;

  void addProcess(String process) {
    String format = DateFormat.yMd().add_Hms().format(DateTime.now());
    _processes.add(' $format: $process');
    notifyListeners();
  }

  void clearProcesses() {
    _processes.clear();
    notifyListeners();
  }
}

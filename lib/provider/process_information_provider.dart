import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

var processInformationProvider =
    ChangeNotifierProvider((ref) => ProcessInformationProvider());

class ProcessInformationProvider extends ChangeNotifier {
  bool _processing = false;
  bool _finished = false;
  bool _failed = false;
  bool _canceled = false;
  final List<String> _failedFiles = [];

  bool get processing => _processing;
  bool get finished => _finished;
  bool get canceled => _canceled;
  bool get failed => _failed;
  List<String> get failedFiles => _failedFiles;

  void setProcessing(bool processing) {
    _processing = processing;
    notifyListeners();
  }

  void setFinished(bool finished) {
    _finished = finished;
    notifyListeners();
  }

  void setCanceled(bool canceled) {
    _canceled = canceled;
    notifyListeners();
  }

  void addFailedFile(String file) {
    _failedFiles.add(file);
    notifyListeners();
  }

  void setFailed(bool failed) {
    _failed = failed;
    notifyListeners();
  }
}

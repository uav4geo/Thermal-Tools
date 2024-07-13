import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

var processInformationProvider =
    ChangeNotifierProvider((ref) => ProcessInformationProvider());

class ProcessInformationProvider extends ChangeNotifier {
  bool _processing = false;
  bool get processing => _processing;

  void setProcessing(bool processing) {
    _processing = processing;
    notifyListeners();
  }

}

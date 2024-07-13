import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

var imagePathModel = ChangeNotifierProvider((ref) => ImagePathModel());

class ImagePathModel extends ChangeNotifier {
  String _path = '';
  bool _dragging = false;
  bool _isFromDrag = false;

  bool get dragging => _dragging;
  String get path => _path;

  bool get isFromDrag => _isFromDrag;

  void setFromDrag(bool isFromDrag) {
    _isFromDrag = isFromDrag;
    notifyListeners();
  }

  void setDragging(bool dragging) {
    _dragging = dragging;
    notifyListeners();
  }

  void setPath(String path) {
    _path = path;
    notifyListeners();
  }
}

import 'package:dji_thermal_tools/themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// https://medium.com/@piyushhh01/building-a-theme-switcher-in-flutter-with-riverpod-e3c1a6555cb4

final themeProvider = ChangeNotifierProvider((ref) => ThemeNotifier());

class ThemeNotifier extends ChangeNotifier {
  ThemeData _themeData = lightTheme;

  ThemeData get themeData => _themeData;

  void toggleDark() {
    _themeData = darkTheme;
    notifyListeners();
  }

  void toggleLight() {
    _themeData = lightTheme;
    notifyListeners();
  }
}

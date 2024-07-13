import 'package:flutter/material.dart';

ThemeData get darkTheme {
  return ThemeData(
    colorScheme: const ColorScheme.highContrastDark(),
    useMaterial3: true,
  );
}

ThemeData get lightTheme {
  return ThemeData(
    colorScheme: const ColorScheme.highContrastLight(),
    useMaterial3: true,
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Colors.blue,
    ),
  );
}

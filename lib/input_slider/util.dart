import 'dart:ui';

import 'package:flutter/cupertino.dart';

/// Calculates the size of [text] in the [TextStyle] [style].
///
/// Credits to Dmitry_Kovalov: https://stackoverflow.com/a/60065737
Size calculateTextSize(String text, TextStyle style) {
  final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr)
    ..layout(minWidth: 0, maxWidth: double.infinity);
  return textPainter.size;
}

import 'package:flutter/material.dart';

import 'input_slider.dart';
import 'util.dart';

/// An [InputSliderForm] groups multiple [InputSlider], aligns them nicely and
/// can be used to provide the same styling to all of them.
///
/// If the same styling parameter is set for both the [InputSliderForm] and one of
/// its children, the child value is chosen.
class InputSliderForm extends StatelessWidget {
  /// The [InputSlider] contained in this [InputSliderForm]
  final List<InputSlider> children;

  /// The color of the active (left) part of the slider.
  ///
  /// By default chooses a color based on the Theme.
  final Color? activeSliderColor;

  /// The color of the inactive (right) part of the slider.
  ///
  /// By default chooses a color based on the Theme.
  final Color? inactiveSliderColor;

  /// The [TextStyle] used in the TextField.
  final TextStyle? textFieldStyle;

  /// Whether the TextField is filled.
  /// Ignored if [inputDecoration] is non-null.
  final bool? filled;

  /// The color with which the TextField is filled, if [filled] is true.
  /// Ignored if [inputDecoration] is non-null.
  ///
  /// By default chooses a color based on the Theme.
  final Color? fillColor;

  /// The border color of the TextField if not focused.
  /// Ignored if [inputDecoration] is non-null.
  ///
  /// By default chooses a color based on the Theme.
  final Color? borderColor;

  /// The border color of the TextField if focused.
  /// Ignored if [inputDecoration] is non-null.
  ///
  /// By default chooses a color based on the Theme.
  final Color? focusBorderColor;

  /// The border radius of the TextField.
  /// Ignored if [inputDecoration] is non-null.
  final BorderRadius? borderRadius;

  /// The [InputDecoration] used by the TextField. If null, use a default decoration.
  final InputDecoration? inputDecoration;

  /// Determines the proportional weight (flex) of the leading widget.
  ///
  /// If null or 0, the leading widget's preferred size is used.
  final int? leadingWeight;

  /// Determines the proportional weight (flex) of the slider.
  ///
  /// If 0 the slider's preferred size is used.
  /// If null the slider is extended.
  final int? sliderWeight;

  /// If true, rotates all [InputSlider] by 90 degrees. Keeps the orientation of the
  /// [TextField]s and the leading widgets. Default is false.
  ///
  /// Note: This puts all [InputSlider] inside a [Row] instead of a [Column].
  final bool vertical;

  const InputSliderForm(
      {Key? key,
      required this.children,
      this.leadingWeight,
      this.sliderWeight,
      this.inputDecoration,
      this.borderRadius,
      this.focusBorderColor,
      this.borderColor,
      this.filled,
      this.fillColor,
      this.textFieldStyle,
      this.inactiveSliderColor,
      this.activeSliderColor,
      this.vertical = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    Size maxTextFieldSize = _calculateMaxTextFieldSize(context: context);

    final sliders = children.map((InputSlider slider) {
      return InputSlider(
        onChange: slider.onChange,
        min: slider.min,
        max: slider.max,
        defaultValue: slider.defaultValue,
        onChangeEnd: slider.onChangeEnd,
        onChangeStart: slider.onChangeStart,
        leading: slider.leading,
        decimalPlaces: slider.decimalPlaces,
        division: slider.division,
        activeSliderColor: slider.activeSliderColor ?? activeSliderColor,
        inactiveSliderColor: slider.inactiveSliderColor ?? inactiveSliderColor,
        textFieldStyle: slider.textFieldStyle ?? textFieldStyle,
        filled: slider.filled ?? filled,
        fillColor: slider.fillColor ?? fillColor,
        borderColor: slider.borderColor ?? borderColor,
        focusBorderColor: slider.focusBorderColor ?? focusBorderColor,
        borderRadius: slider.borderRadius ?? borderRadius,
        inputDecoration: slider.inputDecoration ?? inputDecoration,
        leadingWeight: slider.leadingWeight ?? leadingWeight,
        sliderWeight: slider.sliderWeight ?? sliderWeight,
        textFieldSize: maxTextFieldSize,
        vertical: vertical,
      );
    }).toList();

    return vertical
        ? Row(
        mainAxisSize: MainAxisSize.min,
        children: sliders)
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: sliders,
          );
  }

  /// Calculates the size of the TextField input of [slider].
  Size _calculateMaxTextFieldSize({required BuildContext context}) {
    Size maxTextFieldSize = Size(0, 0);
    children.forEach((slider) {
      TextStyle style =
          slider.textFieldStyle ?? DefaultTextStyle.of(context).style;
      String measureString = slider.max.toString() + ".";
      for (int i = 0; i < slider.decimalPlaces; i++) measureString += "9";
      final textSize = calculateTextSize(measureString, style);
      final textFieldSize = textSize + Offset(8, 4);
      if (textFieldSize.width > maxTextFieldSize.width)
        maxTextFieldSize = textFieldSize;
    });

    return maxTextFieldSize;
  }
}

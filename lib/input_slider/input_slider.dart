library input_slider;

import 'package:flutter/material.dart';
import 'util.dart';

/// An input widget that combines a [Slider] synchronized with a [TextField]
class InputSlider extends StatefulWidget {
  /// Called whenever the value changes by moving the slider or entering a value
  /// into the TextField
  final Function(double) onChange;

  /// Called whenever the user is done moving the slider.
  final Function(double)? onChangeEnd;

  /// Called whenever the user starts moving the slider.
  final Function(double)? onChangeStart;

  /// The minimum value. Every value smaller than this will be clamped.
  final double min;

  /// The maximum value. Every value greater than this will be clamped.
  final double max;

  /// The default value of this InputSlider.
  final double defaultValue;

  /// The number of discrete divisions.
  final int? division;

  /// The color of the active (left) part of the slider.
  ///
  /// By default chooses a color based on the Theme.
  final Color? activeSliderColor;

  /// The color of the inactive (right) part of the slider.
  ///
  /// By default chooses a color based on the Theme.
  final Color? inactiveSliderColor;

  /// The amount of decimal places shown in the TextField.
  final int decimalPlaces;

  /// A leading Widget. This could be a Text or an Icon as a label.
  final Widget? leading;

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

  /// The size of the input [TextField].
  ///
  /// If null, calculates the size based on the [textFieldStyle] and [decimalPlaces].
  final Size? textFieldSize;

  /// If true, rotates the [Slider] by 90 degrees. Keeps the orientation of the
  /// [TextField] and the leading widget. Default is false.
  ///
  /// Note: This puts all widgets ([Slider], [TextField] and leading widget) inside a
  /// Column instead of a row. When using this [InputSlider] inside another Column,
  /// you have to constrain the height of this [InputSlider] by using widgets such
  /// as [SizedBox], [Expanded] or [Flexible].
  final bool vertical;

  const InputSlider(
      {super.key,
      required this.onChange,
      required this.min,
      required this.max,
      required this.defaultValue,
      this.onChangeEnd,
      this.onChangeStart,
      this.leading,
      this.decimalPlaces = 2,
      this.division,
      this.activeSliderColor,
      this.inactiveSliderColor,
      this.textFieldStyle,
      this.filled,
      this.fillColor,
      this.borderColor,
      this.focusBorderColor,
      this.borderRadius,
      this.inputDecoration,
      this.leadingWeight,
      this.sliderWeight,
      this.textFieldSize,
      this.vertical = false});

  @override
  _InputSliderState createState() => _InputSliderState(
      defaultValue: defaultValue, textFieldSize: this.textFieldSize);
}

class _InputSliderState extends State<InputSlider> {
  double defaultValue;
  TextEditingController _controller = TextEditingController();
  Size? textFieldSize;

  _InputSliderState({required this.defaultValue, this.textFieldSize});

  @override
  void initState() {
    super.initState();
    assert(defaultValue >= widget.min && defaultValue <= widget.max,
        "value must be between min and max.");
    _controller = TextEditingController(
        text: defaultValue.toStringAsFixed(widget.decimalPlaces));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (textFieldSize == null) _calculateTextFieldSize();

    final widgets = [
      Flexible(
          flex: widget.leadingWeight ?? 0,
          fit: FlexFit.tight,
          child: Align(alignment: Alignment.centerLeft, child: widget.leading)),
      const Padding(
        padding: EdgeInsets.only(left: 8.0),
      ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: SizedBox(
          width: textFieldSize!.width,
          height: textFieldSize!.height,
          child: Focus(
              child: TextField(
                controller: _controller,
                keyboardType: const TextInputType.numberWithOptions(
                    signed: true, decimal: true),
                style:
                    widget.textFieldStyle ?? DefaultTextStyle.of(context).style,
                onSubmitted: (value) {
                  double parsedValue =
                      double.tryParse(value) ?? this.defaultValue;
                  parsedValue = parsedValue.clamp(widget.min, widget.max);
                  setState(() {
                    this.defaultValue = parsedValue;
                  });
                  _setControllerValue(this.defaultValue);
                  widget.onChangeEnd?.call(this.defaultValue);
                },
                onChanged: (value) {
                  double? parsedValue = double.tryParse(value);
                  if (parsedValue != null &&
                      parsedValue >= widget.min &&
                      parsedValue <= widget.max) {
                    setState(() {
                      this.defaultValue = parsedValue;
                    });
                    _setControllerValue(this.defaultValue);
                  }
                },
                textAlign: TextAlign.center,
                decoration: widget.inputDecoration ??
                    InputDecoration(
                      enabledBorder: OutlineInputBorder(
                          borderRadius:
                              widget.borderRadius ?? BorderRadius.circular(8),
                          borderSide: BorderSide(
                              color: widget.borderColor ??
                                  Theme.of(context).hintColor)),
                      border: OutlineInputBorder(
                          borderRadius:
                              widget.borderRadius ?? BorderRadius.circular(8),
                          borderSide: BorderSide(
                              color: widget.borderColor ??
                                  Theme.of(context).hintColor)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius:
                              widget.borderRadius ?? BorderRadius.circular(8),
                          borderSide: BorderSide(
                              width: 2,
                              color: widget.focusBorderColor ??
                                  Theme.of(context).primaryColor)),
                      filled: widget.filled,
                      fillColor: widget.fillColor,
                      contentPadding: EdgeInsets.only(top: 5),
                    ),
              ),
              onFocusChange: (hasFocus) {
                if (!hasFocus) {
                  this._setControllerValue(this.defaultValue);
                }
              }),
        ),
      ),
      widget.vertical
          ? Flexible(
              flex: widget.sliderWeight ?? 1,
              fit: FlexFit.tight,
              child: RotatedBox(
                quarterTurns: 1,
                child: Slider(
                  value: defaultValue,
                  min: widget.min,
                  max: widget.max,
                  divisions: widget.division,
                  activeColor: widget.activeSliderColor,
                  inactiveColor: widget.inactiveSliderColor,
                  onChangeEnd: widget.onChangeEnd,
                  onChanged: (double value) {
                    setState(() {
                      this.defaultValue = value;
                    });
                    _setControllerValue(value);
                  },
                ),
              ),
            )
          : Flexible(
              flex: widget.sliderWeight ?? 1,
              fit: FlexFit.tight,
              child: Slider(
                value: defaultValue,
                min: widget.min,
                max: widget.max,
                divisions: widget.division,
                activeColor: widget.activeSliderColor,
                inactiveColor: widget.inactiveSliderColor,
                onChangeEnd: widget.onChangeEnd,
                onChanged: (double value) {
                  setState(() {
                    this.defaultValue = value;
                  });
                  _setControllerValue(value);
                },
              ),
            ),
    ];

    return (widget.vertical)
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: widgets,
          )
        : Row(
            children: widgets,
          );
  }

  /// Calculates the size of the TextField input.
  void _calculateTextFieldSize() {
    TextStyle style =
        widget.textFieldStyle ?? DefaultTextStyle.of(context).style;
    String measureString = widget.max.toString() + ".";
    for (int i = 0; i < widget.decimalPlaces; i++) measureString += "9";
    final textSize = calculateTextSize(measureString, style);
    textFieldSize = textSize + Offset(8, 4);
  }

  /// Sets the [_controller] to the String representation of [value], clamped and
  /// with max [widget.decimalPlaces].
  void _setControllerValue(double value) {
    value = value.clamp(widget.min, widget.max);
    setState(() {
      _controller.text = value.toStringAsFixed(widget.decimalPlaces);
    });
    widget.onChange.call(value);
  }
}

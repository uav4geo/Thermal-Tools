import 'package:dji_thermal_tools/input_slider/input_slider.dart';
import 'package:dji_thermal_tools/input_slider/input_slider_form.dart';
import 'package:dji_thermal_tools/provider/environment_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EnvironmentForm extends ConsumerWidget {
  const EnvironmentForm({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
        margin: const EdgeInsets.only(left: 16, right: 16),
        child: InputSliderForm(
            leadingWeight: 18,
            sliderWeight: 20,
            filled: true,
            vertical: false,
            children: [
              InputSlider(
                onChange: (value) {
                  ref.read(environmentModel).setDistance(value);
                },
                min: 1.0,
                max: 25.0,
                decimalPlaces: 0,
                defaultValue: ref.watch(environmentModel).distance,
                leading: const Text("Distance (m):"),
              ),
              InputSlider(
                onChange: (value) {
                  ref.read(environmentModel).setHumidity(value);
                },
                min: 20.0,
                max: 100.0,
                decimalPlaces: 0,
                defaultValue: ref.watch(environmentModel).humidity,
                leading: const Text("Humidity (%):"),
              ),
              InputSlider(
                onChange: (value) {
                  ref.read(environmentModel).setEmissivity(value);
                },
                min: 0.10,
                max: 1.00,
                decimalPlaces: 2,
                defaultValue: ref.watch(environmentModel).emissivity,
                leading: const Text("Emissivity:"),
              ),
              InputSlider(
                onChange: (value) {
                  ref.read(environmentModel).setAmbientTemperature(value);
                },
                min: -40.0,
                max: 80.0,
                decimalPlaces: 1,
                defaultValue: ref.watch(environmentModel).ambientTemperature,
                leading: const Text("Ambient Temperature (°C):"),
              ),
              InputSlider(
                onChange: (value) {
                  ref.read(environmentModel).setReflectedTemperature(value);
                },
                min: -40.0,
                max: 500.0,
                decimalPlaces: 1,
                defaultValue: ref.watch(environmentModel).reflectedTemperature,
                leading: const Text("Reflected Temperature (°C):"),
              )
            ]));
  }
}

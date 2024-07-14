import 'package:dji_thermal_tools/input_slider/input_slider.dart';
import 'package:dji_thermal_tools/input_slider/input_slider_form.dart';
import 'package:dji_thermal_tools/provider/environment_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
                defaultValue: ref.watch(environmentModel).envParams.distance,
                leading: Text(AppLocalizations.of(context)!.distance),
              ),
              InputSlider(
                onChange: (value) {
                  ref.read(environmentModel).setHumidity(value);
                },
                min: 20.0,
                max: 100.0,
                decimalPlaces: 0,
                defaultValue: ref.watch(environmentModel).envParams.humidity,
                leading: Text(AppLocalizations.of(context)!.humidity),
              ),
              InputSlider(
                onChange: (value) {
                  ref.read(environmentModel).setEmissivity(value);
                },
                min: 0.10,
                max: 1.00,
                decimalPlaces: 2,
                defaultValue: ref.watch(environmentModel).envParams.emissivity,
                leading: Text(AppLocalizations.of(context)!.emissivity),
              ),
              InputSlider(
                onChange: (value) {
                  ref.read(environmentModel).setAmbientTemperature(value);
                },
                min: -40.0,
                max: 80.0,
                decimalPlaces: 1,
                defaultValue: ref.watch(environmentModel).envParams.ambient,
                leading: Text(AppLocalizations.of(context)!.ambientTemperature),
              ),
              InputSlider(
                onChange: (value) {
                  ref.read(environmentModel).setReflectedTemperature(value);
                },
                min: -40.0,
                max: 500.0,
                decimalPlaces: 1,
                defaultValue: ref.watch(environmentModel).envParams.reflection,
                leading:
                    Text(AppLocalizations.of(context)!.reflectedTemperature),
              )
            ]));
  }
}

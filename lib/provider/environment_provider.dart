import 'package:dji_thermal_tools/process.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

var environmentModel = ChangeNotifierProvider((ref) => EnvironmentModel());

class EnvironmentModel extends ChangeNotifier {
  bool overrideDefaults = false;

  EnvParams envParams = EnvParams(
    distance: 1.0,
    humidity: 50.0,
    emissivity: 0.95,
    ambient: 20.0,
    reflection: 20.0,
  );

  void reset() {
    notifyListeners();
  }

  void setHumidity(double value) {
    envParams.humidity = value;
    notifyListeners();
  }

  void setEmissivity(double value) {
    envParams.emissivity = value;
    notifyListeners();
  }

  void setAmbientTemperature(double value) {
    envParams.ambient = value;
    notifyListeners();
  }

  void setOverrideDefaults(bool value) {
    overrideDefaults = value;
    notifyListeners();
  }

  void setDistance(double value) {
    envParams.distance = value;
    notifyListeners();
  }

  void setReflectedTemperature(double value) {
    envParams.reflection = value;
    notifyListeners();
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

var environmentModel = ChangeNotifierProvider((ref) => EnvironmentModel());

class EnvironmentModel extends ChangeNotifier {
  bool overrideDefaults = false;
  double distance = 1.0;
  double humidity = 50.0;
  double emissivity = 0.95;
  double ambientTemperature = 20.0;
  double reflectedTemperature = 20.0;

  void reset() {
    distance = 1.0;
    humidity = 50.0;
    emissivity = 0.95;
    ambientTemperature = 20.0;
    reflectedTemperature = 20.0;
    notifyListeners();
  }

  void setHumidity(double value) {
    humidity = value;
    notifyListeners();
  }

  void setEmissivity(double value) {
    emissivity = value;
    notifyListeners();
  }

  void setAmbientTemperature(double value) {
    ambientTemperature = value;
    notifyListeners();
  }

  void setOverrideDefaults(bool value) {
    overrideDefaults = value;
    notifyListeners();
  }

  void setDistance(double value) {
    distance = value;
    notifyListeners();
  }

  void setReflectedTemperature(double value) {
    reflectedTemperature = value;
    notifyListeners();
  }
}

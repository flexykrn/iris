import 'package:vibration/vibration.dart';
import 'package:flutter/foundation.dart';

class VibrationService {
  static final VibrationService _instance = VibrationService._internal();
  factory VibrationService() => _instance;
  VibrationService._internal();

  Future<void> heavyVibration() async {
    try {
      await Vibration.vibrate(duration: 500, amplitude: 255);
    } catch (e) {
      debugPrint('Heavy vibration error: $e');
    }
  }

  Future<void> shortVibration() async {
    try {
      await Vibration.vibrate(duration: 200, amplitude: 255);
    } catch (e) {
      debugPrint('Short vibration error: $e');
    }
  }

  Future<void> longVibration() async {
    try {
      await Vibration.vibrate(duration: 1000, amplitude: 255);
    } catch (e) {
      debugPrint('Long vibration error: $e');
    }
  }

  Future<void> doubleVibration() async {
    try {
      await Vibration.vibrate(duration: 200, amplitude: 255);
      await Future.delayed(Duration(milliseconds: 100));
      await Vibration.vibrate(duration: 200, amplitude: 255);
    } catch (e) {
      debugPrint('Double vibration error: $e');
    }
  }

  Future<void> lightVibration() async {
    try {
      await Vibration.vibrate(duration: 100, amplitude: 128);
    } catch (e) {
      debugPrint('Light vibration error: $e');
    }
  }

  Future<bool> hasVibrator() async {
    try {
      return await Vibration.hasVibrator();
    } catch (e) {
      debugPrint('Vibrator check error: $e');
      return false;
    }
  }
}

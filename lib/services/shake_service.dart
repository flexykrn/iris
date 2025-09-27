import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class ShakeService {
  static final ShakeService _instance = ShakeService._internal();
  factory ShakeService() => _instance;
  ShakeService._internal();

  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  bool _isListening = false;
  double _shakeThreshold = 15.0;
  int _shakeCount = 0;
  DateTime? _lastShakeTime;
  Timer? _shakeResetTimer;

  Function()? onShakeDetected;

  Future<void> startListening() async {
    if (_isListening) return;

    try {
      _isListening = true;
      _accelerometerSubscription = accelerometerEventStream().listen((
        AccelerometerEvent event,
      ) {
        _handleAccelerometerEvent(event);
      });
    } catch (e) {
      debugPrint('Shake detection start error: $e');
      _isListening = false;
    }
  }

  void _handleAccelerometerEvent(AccelerometerEvent event) {
    final double acceleration = sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );

    if (acceleration > _shakeThreshold) {
      final now = DateTime.now();

      // Reset shake count if too much time has passed
      if (_lastShakeTime != null &&
          now.difference(_lastShakeTime!).inMilliseconds > 1000) {
        _shakeCount = 0;
      }

      _shakeCount++;
      _lastShakeTime = now;

      // Trigger shake if we have enough shakes in a short time
      if (_shakeCount >= 2) {
        _triggerShake();
        _shakeCount = 0;
      }

      // Reset shake count after a delay
      _shakeResetTimer?.cancel();
      _shakeResetTimer = Timer(Duration(milliseconds: 500), () {
        _shakeCount = 0;
      });
    }
  }

  void _triggerShake() {
    try {
      // Provide haptic feedback
      HapticFeedback.heavyImpact();

      // Call the callback
      onShakeDetected?.call();
    } catch (e) {
      debugPrint('Shake trigger error: $e');
    }
  }

  Future<void> stopListening() async {
    try {
      _isListening = false;
      await _accelerometerSubscription?.cancel();
      _accelerometerSubscription = null;
      _shakeResetTimer?.cancel();
      _shakeResetTimer = null;
      _shakeCount = 0;
      _lastShakeTime = null;
    } catch (e) {
      debugPrint('Shake detection stop error: $e');
    }
  }

  void setShakeThreshold(double threshold) {
    _shakeThreshold = threshold;
  }

  bool get isListening => _isListening;

  void dispose() {
    stopListening();
  }
}

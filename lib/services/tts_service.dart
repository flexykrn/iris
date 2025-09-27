import 'package:flutter_tts/flutter_tts.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter/foundation.dart';

class TTSService {
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;
  TTSService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      _isInitialized = true;
    } catch (e) {
      debugPrint('TTS initialization error: $e');
    }
  }

  Future<void> speak(String text) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      await _flutterTts.stop();
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('TTS speak error: $e');
    }
  }

  Future<void> speakWithVibration(
    String text, {
    bool heavyVibration = true,
  }) async {
    await speak(text);
    if (heavyVibration) {
      await Vibration.vibrate(duration: 500, amplitude: 255);
    }
  }

  Future<void> speakWithShortVibration(String text) async {
    await speak(text);
    await Vibration.vibrate(duration: 200, amplitude: 255);
  }

  Future<void> speakWithLongVibration(String text) async {
    await speak(text);
    await Vibration.vibrate(duration: 1000, amplitude: 255);
  }

  Future<void> speakWithDoubleVibration(String text) async {
    await speak(text);
    await Vibration.vibrate(duration: 200, amplitude: 255);
    await Future.delayed(Duration(milliseconds: 100));
    await Vibration.vibrate(duration: 200, amplitude: 255);
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      debugPrint('TTS stop error: $e');
    }
  }

  void dispose() {
    _flutterTts.stop();
  }
}

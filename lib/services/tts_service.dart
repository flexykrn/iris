import 'package:flutter_tts/flutter_tts.dart';
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
      await _flutterTts.setSpeechRate(0.6);
      await _flutterTts.setVolume(0.8);
      await _flutterTts.setPitch(1.0);

      // Set up completion handler
      _flutterTts.setCompletionHandler(() {
        debugPrint("TTS completed");
      });

      _isInitialized = true;
      debugPrint('TTS initialized successfully');
    } catch (e) {
      debugPrint('TTS initialization error: $e');
      _isInitialized = false;
    }
  }

  Future<void> speak(String text) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (!_isInitialized) {
      debugPrint('TTS not initialized, cannot speak');
      return;
    }

    try {
      await _flutterTts.stop();
      await Future.delayed(Duration(milliseconds: 100));
      await _flutterTts.speak(text);
      debugPrint('TTS speaking: $text');
    } catch (e) {
      debugPrint('TTS speak error: $e');
    }
  }

  Future<void> speakWithVibration(String text) async {
    await speak(text);
  }

  Future<void> speakWithShortVibration(String text) async {
    await speak(text);
  }

  Future<void> speakWithLongVibration(String text) async {
    await speak(text);
  }

  Future<void> speakWithDoubleVibration(String text) async {
    await speak(text);
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

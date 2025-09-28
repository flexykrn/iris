import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class VitGptAIService {
  static final VitGptAIService _instance = VitGptAIService._internal();
  factory VitGptAIService() => _instance;
  VitGptAIService._internal();

  // VIT-GPT service configuration
  String _baseUrl = 'http://localhost:5000'; // Python server URL
  Duration _timeout = Duration(seconds: 30);

  // Configuration getters/setters
  String get baseUrl => _baseUrl;
  Duration get timeout => _timeout;

  void configure({required String baseUrl, Duration? timeout}) {
    _baseUrl = baseUrl;
    _timeout = timeout ?? Duration(seconds: 30);
  }

  Future<String> getSceneDescription(Uint8List imageBytes) async {
    return await _processImageWithMode(imageBytes, 'scene_description');
  }

  Future<String> getNavigationGuidance(Uint8List imageBytes) async {
    return await _processImageWithMode(imageBytes, 'navigation');
  }

  Future<String> _processImageWithMode(
    Uint8List imageBytes,
    String mode,
  ) async {
    try {
      final uri = Uri.parse('$_baseUrl/analyze_image');

      final request = http.MultipartRequest('POST', uri);
      request.headers['Content-Type'] = 'multipart/form-data';

      // Add image file
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: 'image.jpg',
        ),
      );

      // Add mode parameter
      request.fields['mode'] = mode;

      // Send request
      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final Map<String, dynamic> result = json.decode(response.body);

        if (mode == 'scene_description') {
          return result['description'] ?? 'Unable to describe the scene';
        } else if (mode == 'navigation') {
          return result['navigation'] ??
              'Unable to provide navigation guidance';
        }

        return result['description'] ?? 'Unable to process image';
      } else {
        throw Exception(
          'AI service error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('VIT-GPT AI service error: $e');
      return 'Error processing $mode';
    }
  }

  Future<bool> testConnection() async {
    try {
      final uri = Uri.parse('$_baseUrl/health');
      final response = await http.get(uri).timeout(Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('VIT-GPT service connection test failed: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> getServiceInfo() async {
    try {
      final uri = Uri.parse('$_baseUrl/info');
      final response = await http.get(uri).timeout(_timeout);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get service info: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Get service info error: $e');
      return {
        'error': 'Failed to get service information',
        'details': e.toString(),
        'service': 'VIT-GPT AI Service',
        'model': 'nlpconnect/vit-gpt2-image-captioning',
      };
    }
  }
}

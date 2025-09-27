import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class DockerAIService {
  static final DockerAIService _instance = DockerAIService._internal();
  factory DockerAIService() => _instance;
  DockerAIService._internal();

  // Docker AI service configuration
  String _baseUrl = 'http://localhost:8000';
  String _apiKey = '';
  Duration _timeout = Duration(seconds: 10);

  // Configuration getters/setters
  String get baseUrl => _baseUrl;
  String get apiKey => _apiKey;
  Duration get timeout => _timeout;

  void configure({required String baseUrl, String? apiKey, Duration? timeout}) {
    _baseUrl = baseUrl;
    _apiKey = apiKey ?? '';
    _timeout = timeout ?? Duration(seconds: 10);
  }

  Future<Map<String, dynamic>> processImage({
    required Uint8List imageBytes,
    required String mode,
    Map<String, dynamic>? additionalParams,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/process');

      final request = http.MultipartRequest('POST', uri);

      // Add headers
      request.headers['Content-Type'] = 'multipart/form-data';
      if (_apiKey.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $_apiKey';
      }

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

      // Add additional parameters
      if (additionalParams != null) {
        additionalParams.forEach((key, value) {
          request.fields[key] = value.toString();
        });
      }

      // Send request
      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final Map<String, dynamic> result = json.decode(response.body);
        return result;
      } else {
        throw Exception(
          'AI service error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('Docker AI service error: $e');
      throw Exception('Failed to process image: $e');
    }
  }

  Future<String> getSceneDescription(Uint8List imageBytes) async {
    try {
      final result = await processImage(
        imageBytes: imageBytes,
        mode: 'scene_description',
        additionalParams: {
          'detail_level': 'high',
          'include_objects': 'true',
          'include_people': 'true',
          'include_text': 'true',
        },
      );

      return result['description'] ?? 'Unable to describe the scene';
    } catch (e) {
      debugPrint('Scene description error: $e');
      return 'Error processing scene description';
    }
  }

  Future<Map<String, dynamic>> getNavigationGuidance(
    Uint8List imageBytes,
  ) async {
    try {
      final result = await processImage(
        imageBytes: imageBytes,
        mode: 'navigation',
        additionalParams: {
          'include_obstacles': 'true',
          'include_directions': 'true',
          'include_distance_estimation': 'true',
        },
      );

      return {
        'directions':
            result['directions'] ?? 'Unable to provide navigation guidance',
        'obstacles': result['obstacles'] ?? [],
        'confidence': result['confidence'] ?? 0.0,
        'distance_estimation': result['distance_estimation'] ?? 'Unknown',
      };
    } catch (e) {
      debugPrint('Navigation guidance error: $e');
      return {
        'directions': 'Error processing navigation guidance',
        'obstacles': [],
        'confidence': 0.0,
        'distance_estimation': 'Unknown',
      };
    }
  }

  Future<bool> testConnection() async {
    try {
      final uri = Uri.parse('$_baseUrl/health');
      final response = await http.get(uri).timeout(_timeout);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('AI service connection test failed: $e');
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
      };
    }
  }
}

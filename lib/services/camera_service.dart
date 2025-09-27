import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

enum CameraSource { device, esp32 }

class CameraService {
  static final CameraService _instance = CameraService._internal();
  factory CameraService() => _instance;
  CameraService._internal();

  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isCapturing = false;
  bool _isStreaming = false;
  Timer? _captureTimer;
  StreamController<Uint8List>? _frameStreamController;
  StreamController<Uint8List>? _previewStreamController;

  // ESP32 Camera settings
  String _esp32CameraUrl = 'http://192.168.1.100:81/stream';
  CameraSource _currentSource = CameraSource.device;

  // Streams
  Stream<Uint8List> get frameStream => _frameStreamController!.stream;
  Stream<Uint8List> get previewStream => _previewStreamController!.stream;

  // Getters
  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;
  bool get isCapturing => _isCapturing;
  bool get isStreaming => _isStreaming;
  CameraSource get currentSource => _currentSource;
  String get esp32CameraUrl => _esp32CameraUrl;

  Future<bool> initialize({CameraSource source = CameraSource.device}) async {
    try {
      _currentSource = source;

      if (source == CameraSource.device) {
        return await _initializeDeviceCamera();
      } else {
        return await _initializeEsp32Camera();
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
      return false;
    }
  }

  Future<bool> _initializeDeviceCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        debugPrint('No cameras available');
        return false;
      }

      // Find rear camera
      CameraDescription? rearCamera;
      for (var camera in _cameras) {
        if (camera.lensDirection == CameraLensDirection.back) {
          rearCamera = camera;
          break;
        }
      }

      if (rearCamera == null) {
        debugPrint('No rear camera found');
        return false;
      }

      _controller = CameraController(
        rearCamera,
        ResolutionPreset.high, // Higher resolution for better AI processing
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      _isInitialized = true;
      _frameStreamController = StreamController<Uint8List>.broadcast();
      _previewStreamController = StreamController<Uint8List>.broadcast();

      return true;
    } catch (e) {
      debugPrint('Device camera initialization error: $e');
      return false;
    }
  }

  Future<bool> _initializeEsp32Camera() async {
    try {
      // Test ESP32 camera connection
      final response = await http
          .get(Uri.parse(_esp32CameraUrl))
          .timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        _isInitialized = true;
        _frameStreamController = StreamController<Uint8List>.broadcast();
        _previewStreamController = StreamController<Uint8List>.broadcast();
        return true;
      } else {
        debugPrint('ESP32 camera not accessible: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('ESP32 camera initialization error: $e');
      return false;
    }
  }

  Future<void> startStreaming({int fps = 30}) async {
    if (!_isInitialized || _isStreaming) return;

    try {
      _isStreaming = true;

      if (_currentSource == CameraSource.device) {
        await _startDeviceStreaming(fps);
      } else {
        await _startEsp32Streaming(fps);
      }
    } catch (e) {
      debugPrint('Start streaming error: $e');
      _isStreaming = false;
    }
  }

  Future<void> _startDeviceStreaming(int fps) async {
    if (_controller == null) return;

    try {
      await _controller!.resumePreview();

      // Start frame capture for AI processing
      _captureTimer = Timer.periodic(
        Duration(milliseconds: (1000 / fps).round()),
        (timer) => _captureDeviceFrame(),
      );
    } catch (e) {
      debugPrint('Device streaming error: $e');
    }
  }

  Future<void> _startEsp32Streaming(int fps) async {
    // Start ESP32 frame capture
    _captureTimer = Timer.periodic(
      Duration(milliseconds: (1000 / fps).round()),
      (timer) => _captureEsp32Frame(),
    );
  }

  Future<void> stopStreaming() async {
    try {
      _isStreaming = false;
      _captureTimer?.cancel();
      _captureTimer = null;

      if (_currentSource == CameraSource.device && _controller != null) {
        await _controller!.pausePreview();
      }
    } catch (e) {
      debugPrint('Stop streaming error: $e');
    }
  }

  Future<void> startCapturing({int fps = 1}) async {
    if (!_isInitialized || _isCapturing) return;

    try {
      _isCapturing = true;
      _captureTimer = Timer.periodic(
        Duration(milliseconds: (1000 / fps).round()),
        (timer) => _captureFrame(),
      );
    } catch (e) {
      debugPrint('Start capturing error: $e');
      _isCapturing = false;
    }
  }

  Future<void> stopCapturing() async {
    try {
      _isCapturing = false;
      _captureTimer?.cancel();
      _captureTimer = null;
    } catch (e) {
      debugPrint('Stop capturing error: $e');
    }
  }

  Future<void> _captureDeviceFrame() async {
    if (!_isInitialized || !_isStreaming || _controller == null) return;

    try {
      final XFile image = await _controller!.takePicture();
      final Uint8List imageBytes = await image.readAsBytes();

      // Send to preview stream for display
      _previewStreamController?.add(imageBytes);

      // Send to frame stream for AI processing
      _frameStreamController?.add(imageBytes);
    } catch (e) {
      debugPrint('Device frame capture error: $e');
    }
  }

  Future<void> _captureEsp32Frame() async {
    if (!_isInitialized || !_isStreaming) return;

    try {
      final response = await http
          .get(Uri.parse(_esp32CameraUrl))
          .timeout(Duration(seconds: 2));

      if (response.statusCode == 200) {
        final Uint8List imageBytes = response.bodyBytes;

        // Send to preview stream for display
        _previewStreamController?.add(imageBytes);

        // Send to frame stream for AI processing
        _frameStreamController?.add(imageBytes);
      }
    } catch (e) {
      debugPrint('ESP32 frame capture error: $e');
    }
  }

  Future<void> _captureFrame() async {
    if (!_isInitialized || !_isCapturing) return;

    try {
      if (_currentSource == CameraSource.device && _controller != null) {
        final XFile image = await _controller!.takePicture();
        final Uint8List imageBytes = await image.readAsBytes();
        _frameStreamController?.add(imageBytes);
      } else {
        await _captureEsp32Frame();
      }
    } catch (e) {
      debugPrint('Frame capture error: $e');
    }
  }

  Future<void> startPreview() async {
    if (!_isInitialized) return;

    try {
      if (_currentSource == CameraSource.device && _controller != null) {
        await _controller!.resumePreview();
      }
    } catch (e) {
      debugPrint('Start preview error: $e');
    }
  }

  Future<void> stopPreview() async {
    if (!_isInitialized) return;

    try {
      if (_currentSource == CameraSource.device && _controller != null) {
        await _controller!.pausePreview();
      }
    } catch (e) {
      debugPrint('Stop preview error: $e');
    }
  }

  Future<bool> switchCameraSource(
    CameraSource source, {
    String? esp32Url,
  }) async {
    try {
      await stopStreaming();
      await stopCapturing();
      await dispose();

      if (source == CameraSource.esp32 && esp32Url != null) {
        _esp32CameraUrl = esp32Url;
      }

      return await initialize(source: source);
    } catch (e) {
      debugPrint('Switch camera source error: $e');
      return false;
    }
  }

  Future<void> dispose() async {
    try {
      await stopStreaming();
      await stopCapturing();
      await _controller?.dispose();
      _controller = null;
      _isInitialized = false;
      await _frameStreamController?.close();
      await _previewStreamController?.close();
      _frameStreamController = null;
      _previewStreamController = null;
    } catch (e) {
      debugPrint('Camera dispose error: $e');
    }
  }
}

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import '../models/app_state.dart';
import '../services/tts_service.dart';
import '../services/camera_service.dart';
import '../services/mock_ai_service.dart';
import '../services/docker_ai_service.dart';
import '../services/permission_service.dart';
import '../services/shake_service.dart';

class AppStateProvider extends ChangeNotifier {
  AppState _state = AppState();
  final TTSService _ttsService = TTSService();
  final CameraService _cameraService = CameraService();
  final MockAIService _mockAIService = MockAIService();
  final DockerAIService _dockerAIService = DockerAIService();
  final PermissionService _permissionService = PermissionService();
  final ShakeService _shakeService = ShakeService();

  // AI service configuration
  bool _useDockerAI = false;
  String _dockerAIUrl = 'http://localhost:8000';

  AppState get state => _state;

  CameraController? getCameraController() {
    return _cameraService.controller;
  }

  Future<void> initialize() async {
    try {
      _updateState(status: AppStatus.initializing);

      // Initialize TTS
      await _ttsService.initialize();

      // Set up shake detection
      _shakeService.onShakeDetected = _handleShakeDetected;
      await _shakeService.startListening();

      // Request permissions
      _updateState(status: AppStatus.requestingPermissions);
      final hasPermissions = await _permissionService.requestAllPermissions();

      if (!hasPermissions) {
        _updateState(
          status: AppStatus.error,
          hasError: true,
          errorMessage: 'Required permissions not granted',
        );
        await _ttsService.speakWithDoubleVibration(
          'Permission denied. Please grant camera and microphone access.',
        );
        return;
      }

      // Initialize camera
      _updateState(status: AppStatus.startingCamera);
      final cameraInitialized = await _cameraService.initialize();

      if (!cameraInitialized) {
        _updateState(
          status: AppStatus.error,
          hasError: true,
          errorMessage: 'Camera initialization failed',
        );
        await _ttsService.speakWithDoubleVibration(
          'Camera initialization failed.',
        );
        return;
      }

      // Start camera streaming and capturing
      await _cameraService.startPreview();
      await _cameraService.startStreaming(fps: 30); // Continuous streaming
      await _cameraService.startCapturing(fps: 1); // AI processing frames

      _updateState(
        status: AppStatus.idle,
        isCameraActive: true,
        isCapturing: false,
      );

      // Welcome message with instructions
      await _ttsService.speakWithVibration(
        'Iris started. Swipe left for scene description mode. Swipe right for navigation mode.',
      );
    } catch (e) {
      _updateState(
        status: AppStatus.error,
        hasError: true,
        errorMessage: e.toString(),
      );
      await _ttsService.speakWithDoubleVibration('Initialization error: $e');
    }
  }

  StreamSubscription<Uint8List>? _frameSubscription;

  void _startFrameProcessing() {
    // Cancel existing subscription if any
    _frameSubscription?.cancel();

    _frameSubscription = _cameraService.frameStream.listen((
      Uint8List imageBytes,
    ) async {
      if (_state.status != AppStatus.ready || !_state.isCapturing) return;

      try {
        String description;
        if (_state.currentMode == AppMode.sceneDescription) {
          if (_useDockerAI) {
            description = await _dockerAIService.getSceneDescription(
              imageBytes,
            );
          } else {
            description = await _mockAIService.getSceneDescription();
          }
          _updateState(lastDescription: description);
          await _ttsService.speakWithShortVibration(description);
        } else {
          Map<String, dynamic> nav;
          if (_useDockerAI) {
            nav = await _dockerAIService.getNavigationGuidance(imageBytes);
          } else {
            nav = await _mockAIService.getNavigationGuidance();
          }
          description = nav['directions'];
          _updateState(lastNavigation: description);
          await _ttsService.speakWithShortVibration(description);
        }
      } catch (e) {
        debugPrint('Frame processing error: $e');
        await _ttsService.speakWithDoubleVibration('Processing error');
      }
    });
  }

  Future<void> switchToSceneDescription() async {
    if (_state.currentMode == AppMode.sceneDescription) return;

    try {
      _updateState(
        currentMode: AppMode.sceneDescription,
        status: AppStatus.ready,
        isCapturing: true,
      );
      await _ttsService.speakWithShortVibration('Scene description mode');

      // Start processing frames only when user switches to this mode
      _startFrameProcessing();
    } catch (e) {
      debugPrint('Error switching to scene description: $e');
      _updateState(
        status: AppStatus.error,
        hasError: true,
        errorMessage: 'Failed to switch to scene description mode',
      );
    }
  }

  Future<void> switchToNavigation() async {
    if (_state.currentMode == AppMode.navigation) return;

    try {
      _updateState(
        currentMode: AppMode.navigation,
        status: AppStatus.ready,
        isCapturing: true,
      );
      await _ttsService.speakWithShortVibration('Navigation mode');

      // Start processing frames only when user switches to this mode
      _startFrameProcessing();
    } catch (e) {
      debugPrint('Error switching to navigation: $e');
      _updateState(
        status: AppStatus.error,
        hasError: true,
        errorMessage: 'Failed to switch to navigation mode',
      );
    }
  }

  Future<void> togglePause() async {
    if (_state.status == AppStatus.paused) {
      await _cameraService.startCapturing();
      _updateState(status: AppStatus.ready, isCapturing: true);
      await _ttsService.speakWithShortVibration('Resumed');
    } else {
      await _cameraService.stopCapturing();
      _updateState(status: AppStatus.paused, isCapturing: false);
      await _ttsService.speakWithShortVibration('Paused');
    }
  }

  Future<bool> switchCameraSource(
    CameraSource source, {
    String? esp32Url,
  }) async {
    try {
      final success = await _cameraService.switchCameraSource(
        source,
        esp32Url: esp32Url,
      );
      if (success) {
        await _cameraService.startStreaming(fps: 30);
        await _cameraService.startCapturing(fps: 1);
        await _ttsService.speakWithShortVibration(
          source == CameraSource.device
              ? 'Switched to device camera'
              : 'Switched to ESP32 camera',
        );
      }
      return success;
    } catch (e) {
      debugPrint('Camera source switch error: $e');
      await _ttsService.speakWithDoubleVibration('Failed to switch camera');
      return false;
    }
  }

  Future<void> configureDockerAI(String url, {String? apiKey}) async {
    try {
      _dockerAIUrl = url;
      _dockerAIService.configure(
        baseUrl: url,
        apiKey: apiKey,
        timeout: Duration(seconds: 10),
      );

      // Test connection
      final isConnected = await _dockerAIService.testConnection();
      if (isConnected) {
        _useDockerAI = true;
        await _ttsService.speakWithShortVibration(
          'Docker AI service connected',
        );
      } else {
        _useDockerAI = false;
        await _ttsService.speakWithDoubleVibration(
          'Docker AI service connection failed',
        );
      }
    } catch (e) {
      debugPrint('Docker AI configuration error: $e');
      _useDockerAI = false;
      await _ttsService.speakWithDoubleVibration(
        'Docker AI configuration failed',
      );
    }
  }

  void toggleAIService() {
    _useDockerAI = !_useDockerAI;
    _ttsService.speakWithShortVibration(
      _useDockerAI ? 'Using Docker AI service' : 'Using mock AI service',
    );
  }

  bool get useDockerAI => _useDockerAI;
  String get dockerAIUrl => _dockerAIUrl;

  Future<void> exitApp() async {
    await _ttsService.speakWithLongVibration('Exiting Iris');
    await _cleanup();
  }

  void _handleShakeDetected() async {
    if (_state.status == AppStatus.ready) {
      await _ttsService.speakWithVibration('Iris active');
    } else if (_state.status == AppStatus.paused) {
      await togglePause();
    }
  }

  void _updateState({
    AppMode? currentMode,
    AppStatus? status,
    bool? isCameraActive,
    bool? isCapturing,
    String? lastDescription,
    String? lastNavigation,
    bool? hasError,
    String? errorMessage,
  }) {
    _state = _state.copyWith(
      currentMode: currentMode,
      status: status,
      isCameraActive: isCameraActive,
      isCapturing: isCapturing,
      lastDescription: lastDescription,
      lastNavigation: lastNavigation,
      hasError: hasError,
      errorMessage: errorMessage,
    );
    notifyListeners();
  }

  Future<void> _cleanup() async {
    try {
      _frameSubscription?.cancel();
      await _cameraService.dispose();
      await _shakeService.stopListening();
      await _ttsService.stop();
    } catch (e) {
      debugPrint('Cleanup error: $e');
    }
  }

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }
}

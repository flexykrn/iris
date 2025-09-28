import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import '../models/app_state.dart';
import '../services/tts_service.dart';
import '../services/camera_service.dart';
import '../services/mock_ai_service.dart';
import '../services/docker_ai_service.dart';
import '../services/vitgpt_ai_service.dart';
import '../services/permission_service.dart';
import '../services/shake_service.dart';

class AppStateProvider extends ChangeNotifier {
  AppState _state = AppState();
  final TTSService _ttsService = TTSService();
  final CameraService _cameraService = CameraService();
  final MockAIService _mockAIService = MockAIService();
  final DockerAIService _dockerAIService = DockerAIService();
  final VitGptAIService _vitGptAIService = VitGptAIService();
  final PermissionService _permissionService = PermissionService();
  final ShakeService _shakeService = ShakeService();

  // AI service configuration
  bool _useDockerAI = false;
  bool _useVitGptAI = true; // Use VIT-GPT by default
  String _dockerAIUrl = 'http://localhost:8000';
  String _vitGptUrl = 'http://localhost:5000';

  // ESP32 Camera configuration - MCA-WR-2 network
  String _esp32CameraUrl = 'http://192.168.0.144/capture';

  AppState get state => _state;

  CameraController? getCameraController() {
    return _cameraService.controller;
  }

  CameraService getCameraService() {
    return _cameraService;
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

      // Configure VIT-GPT AI service
      _vitGptAIService.configure(
        baseUrl: _vitGptUrl,
        timeout: Duration(seconds: 30),
      );

      // Test VIT-GPT connection
      final vitGptConnected = await _vitGptAIService.testConnection();
      if (vitGptConnected) {
        _useVitGptAI = true;
        _useDockerAI = false;
        debugPrint('VIT-GPT AI service connected and ready');
        await _ttsService.speakWithShortVibration('VIT-GPT AI ready');
      } else {
        debugPrint('VIT-GPT AI service not available, using mock service');
        _useVitGptAI = false;
        await _ttsService.speakWithShortVibration('Using offline mode');
      }

      // Try to initialize ESP32 camera first
      _updateState(status: AppStatus.startingCamera);
      bool cameraInitialized = false;

      // Try ESP32 camera first with configured URL
      debugPrint('Attempting to initialize ESP32 camera...');
      _cameraService.updateEsp32Url(_esp32CameraUrl);
      cameraInitialized = await _cameraService.initialize(
        source: CameraSource.esp32,
      );

      if (cameraInitialized) {
        debugPrint('ESP32 camera initialized successfully');
        await _ttsService.speakWithShortVibration('ESP32 camera connected');
      } else {
        // Fallback to device camera
        debugPrint('ESP32 camera failed, trying device camera');
        cameraInitialized = await _cameraService.initialize(
          source: CameraSource.device,
        );

        if (cameraInitialized) {
          debugPrint('Device camera initialized successfully');
          await _ttsService.speakWithShortVibration('Device camera connected');
        }
      }

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
      debugPrint('Starting camera preview and streaming...');
      await _cameraService.startPreview();
      await _cameraService.startStreaming(
        fps: 30,
      ); // Continuous streaming for preview
      await _cameraService.startCapturing(fps: 1); // AI processing frames
      debugPrint('Camera streaming and capturing started');

      _updateState(
        status: AppStatus.idle,
        isCameraActive: true,
        isCapturing: false,
      );

      // Welcome message with instructions
      final aiService = _useVitGptAI ? 'VIT-GPT AI' : 'Mock AI';
      await _ttsService.speakWithVibration(
        'Iris started with $aiService. Swipe left for scene description. Swipe right for navigation.',
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
        String result;
        debugPrint(
          'Processing frame from ESP32-CAM (${imageBytes.length} bytes)',
        );

        if (_state.currentMode == AppMode.sceneDescription) {
          if (_useVitGptAI) {
            debugPrint('Getting scene description from VIT-GPT...');
            result = await _vitGptAIService.getSceneDescription(imageBytes);
            debugPrint('VIT-GPT scene description: $result');
          } else if (_useDockerAI) {
            result = await _dockerAIService.getSceneDescription(imageBytes);
          } else {
            result = await _mockAIService.getSceneDescription();
          }
          _updateState(lastDescription: result);
          await _ttsService.speakWithShortVibration(result);
        } else {
          if (_useVitGptAI) {
            debugPrint('Getting navigation guidance from VIT-GPT...');
            result = await _vitGptAIService.getNavigationGuidance(imageBytes);
            debugPrint('VIT-GPT navigation: $result');
          } else if (_useDockerAI) {
            final nav = await _dockerAIService.getNavigationGuidance(
              imageBytes,
            );
            result = nav['directions'];
          } else {
            final nav = await _mockAIService.getNavigationGuidance();
            result = nav['directions'];
          }
          _updateState(lastNavigation: result);
          await _ttsService.speakWithShortVibration(result);
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
      await _ttsService.speakWithShortVibration(
        'Scene description mode activated',
      );

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
      await _ttsService.speakWithShortVibration('Navigation mode activated');

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
        _useVitGptAI = false;
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

  Future<void> configureVitGptAI(String url) async {
    try {
      _vitGptUrl = url;
      _vitGptAIService.configure(baseUrl: url, timeout: Duration(seconds: 30));

      // Test connection
      final isConnected = await _vitGptAIService.testConnection();
      if (isConnected) {
        _useVitGptAI = true;
        _useDockerAI = false;
        await _ttsService.speakWithShortVibration(
          'VIT-GPT AI service connected',
        );
      } else {
        _useVitGptAI = false;
        await _ttsService.speakWithDoubleVibration(
          'VIT-GPT AI service connection failed',
        );
      }
    } catch (e) {
      debugPrint('VIT-GPT AI configuration error: $e');
      _useVitGptAI = false;
      await _ttsService.speakWithDoubleVibration(
        'VIT-GPT AI configuration failed',
      );
    }
  }

  Future<void> configureEsp32Camera(String url) async {
    try {
      _esp32CameraUrl = url;

      // Test ESP32 camera connection
      final success = await _cameraService.switchCameraSource(
        CameraSource.esp32,
        esp32Url: url,
      );

      if (success) {
        await _ttsService.speakWithShortVibration('ESP32 camera configured');
      } else {
        await _ttsService.speakWithDoubleVibration(
          'ESP32 camera connection failed',
        );
      }
    } catch (e) {
      debugPrint('ESP32 camera configuration error: $e');
      await _ttsService.speakWithDoubleVibration(
        'ESP32 camera configuration failed',
      );
    }
  }

  void toggleAIService() {
    if (_useVitGptAI) {
      _useVitGptAI = false;
      _useDockerAI = true;
      _ttsService.speakWithShortVibration('Using Docker AI service');
    } else if (_useDockerAI) {
      _useDockerAI = false;
      _useVitGptAI = false;
      _ttsService.speakWithShortVibration('Using mock AI service');
    } else {
      _useVitGptAI = true;
      _useDockerAI = false;
      _ttsService.speakWithShortVibration('Using VIT-GPT AI service');
    }
  }

  bool get useDockerAI => _useDockerAI;
  bool get useVitGptAI => _useVitGptAI;
  String get dockerAIUrl => _dockerAIUrl;
  String get vitGptUrl => _vitGptUrl;
  String get esp32CameraUrl => _esp32CameraUrl;

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

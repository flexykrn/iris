import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  Future<bool> requestAllPermissions() async {
    try {
      // Request camera permission
      final cameraStatus = await Permission.camera.request();
      if (cameraStatus != PermissionStatus.granted) {
        return false;
      }

      // Request microphone permission
      final micStatus = await Permission.microphone.request();
      if (micStatus != PermissionStatus.granted) {
        return false;
      }

      // Request notification permission for foreground service
      await Permission.notification.request();

      // Request system alert window permission
      await Permission.systemAlertWindow.request();

      // Request battery optimization ignore
      await Permission.ignoreBatteryOptimizations.request();

      return cameraStatus == PermissionStatus.granted &&
          micStatus == PermissionStatus.granted;
    } catch (e) {
      debugPrint('Permission request error: $e');
      return false;
    }
  }

  Future<bool> checkCameraPermission() async {
    try {
      final status = await Permission.camera.status;
      return status == PermissionStatus.granted;
    } catch (e) {
      debugPrint('Camera permission check error: $e');
      return false;
    }
  }

  Future<bool> checkMicrophonePermission() async {
    try {
      final status = await Permission.microphone.status;
      return status == PermissionStatus.granted;
    } catch (e) {
      debugPrint('Microphone permission check error: $e');
      return false;
    }
  }

  Future<bool> checkAllRequiredPermissions() async {
    try {
      final cameraStatus = await Permission.camera.status;
      final micStatus = await Permission.microphone.status;

      return cameraStatus == PermissionStatus.granted &&
          micStatus == PermissionStatus.granted;
    } catch (e) {
      debugPrint('Permission check error: $e');
      return false;
    }
  }
}

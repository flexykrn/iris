import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/camera_service.dart';

class CameraPreviewWidget extends StatefulWidget {
  final CameraService cameraService;
  final bool showPreview;

  const CameraPreviewWidget({
    super.key,
    required this.cameraService,
    this.showPreview = true,
  });

  @override
  State<CameraPreviewWidget> createState() => _CameraPreviewWidgetState();
}

class _CameraPreviewWidgetState extends State<CameraPreviewWidget> {
  StreamSubscription<Uint8List>? _previewSubscription;
  Uint8List? _currentFrame;

  @override
  void initState() {
    super.initState();
    _startPreviewStream();
  }

  @override
  void dispose() {
    _previewSubscription?.cancel();
    super.dispose();
  }

  void _startPreviewStream() {
    if (!widget.showPreview) return;

    debugPrint(
      'Starting preview stream for ${widget.cameraService.currentSource}',
    );

    _previewSubscription = widget.cameraService.previewStream.listen(
      (Uint8List frameData) {
        debugPrint('Received preview frame: ${frameData.length} bytes');
        if (mounted) {
          setState(() {
            _currentFrame = frameData;
          });
          debugPrint('Preview frame updated in UI');
        }
      },
      onError: (error) {
        debugPrint('Preview stream error: $error');
      },
    );

    debugPrint('Preview stream subscription created');
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showPreview) {
      return Container();
    }

    return Positioned.fill(
      child:
          widget.cameraService.currentSource == CameraSource.device
              ? _buildDeviceCameraPreview()
              : _buildEsp32CameraPreview(),
    );
  }

  Widget _buildDeviceCameraPreview() {
    final controller = widget.cameraService.controller;

    if (controller == null || !controller.value.isInitialized) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              SizedBox(height: 16),
              Text(
                'Initializing Camera...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return CameraPreview(controller);
  }

  Widget _buildEsp32CameraPreview() {
    if (_currentFrame == null) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                strokeWidth: 3,
              ),
              SizedBox(height: 16),
              Text(
                'Connecting to ESP32 Camera...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                'Make sure ESP32 is connected to WiFi',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Image.memory(
        _currentFrame!,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off, color: Colors.orange, size: 48),
                  SizedBox(height: 16),
                  Text(
                    'ESP32 Camera Error',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  Text(
                    'Check WiFi connection and IP address',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Current URL: ${widget.cameraService.esp32CameraUrl}',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

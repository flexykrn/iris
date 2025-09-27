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

    _previewSubscription = widget.cameraService.previewStream.listen(
      (Uint8List frameData) {
        if (mounted) {
          setState(() {
            _currentFrame = frameData;
          });
        }
      },
      onError: (error) {
        debugPrint('Preview stream error: $error');
      },
    );
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
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              SizedBox(height: 16),
              Text(
                'Connecting to ESP32 Camera...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Image.memory(
      _currentFrame!,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.black,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.camera_alt_outlined, color: Colors.white, size: 48),
                SizedBox(height: 16),
                Text(
                  'ESP32 Camera Error',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                Text(
                  'Check connection',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

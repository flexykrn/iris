import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../models/app_state.dart';
import '../services/camera_service.dart';
import '../widgets/camera_preview_widget.dart';
import 'settings_screen.dart';

class IrisHomeScreen extends StatefulWidget {
  const IrisHomeScreen({super.key});

  @override
  State<IrisHomeScreen> createState() => _IrisHomeScreenState();
}

class _IrisHomeScreenState extends State<IrisHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppStateProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appStateProvider, child) {
        final state = appStateProvider.state;

        return Scaffold(
          backgroundColor: Colors.black,
          body: GestureDetector(
            onPanStart: (details) => _handlePanStart(details),
            onPanUpdate: (details) => _handlePanUpdate(details),
            onPanEnd: (details) => _handlePanEnd(details),
            child: SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: Stack(
                children: [
                  // Camera preview - always show when camera is active
                  if (state.isCameraActive)
                    CameraPreviewWidget(
                      cameraService:
                          context.read<AppStateProvider>().getCameraService(),
                      showPreview: true,
                    ),

                  // Main UI overlay
                  _buildMainUI(state),

                  // Error overlay
                  if (state.hasError) _buildErrorOverlay(state),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainUI(AppState state) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top status bar with settings button
          _buildStatusBar(state),

          // Center content
          Expanded(child: _buildCenterContent(state)),

          // Bottom controls
          _buildBottomControls(state),
        ],
      ),
    );
  }

  Widget _buildStatusBar(AppState state) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        border: Border(bottom: BorderSide(color: Colors.white, width: 2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'IRIS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _getStatusText(state),
                      style: TextStyle(
                        color: Colors.yellow,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (state.status == AppStatus.ready)
                      Text(
                        _getModeText(state.currentMode),
                        style: TextStyle(
                          color: Colors.cyan,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SettingsScreen()),
                  );
                },
                icon: Icon(Icons.settings, color: Colors.white, size: 28),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCenterContent(AppState state) {
    if (state.status == AppStatus.initializing ||
        state.status == AppStatus.requestingPermissions ||
        state.status == AppStatus.startingCamera) {
      return _buildLoadingContent();
    }

    if (state.status == AppStatus.idle) {
      return _buildIdleContent();
    }

    if (state.status == AppStatus.ready) {
      return _buildReadyContent(state);
    }

    if (state.status == AppStatus.paused) {
      return _buildPausedContent();
    }

    return Container();
  }

  Widget _buildLoadingContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            strokeWidth: 4,
          ),
          SizedBox(height: 20),
          Text(
            'Initializing Iris...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadyContent(AppState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            state.currentMode == AppMode.sceneDescription
                ? Icons.visibility
                : Icons.navigation,
            size: 80,
            color: Colors.white,
          ),
          SizedBox(height: 20),
          Text(
            state.currentMode == AppMode.sceneDescription
                ? 'SCENE DESCRIPTION'
                : 'NAVIGATION',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          SizedBox(height: 10),
          if (state.lastDescription.isNotEmpty ||
              state.lastNavigation.isNotEmpty)
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 1),
              ),
              child: Text(
                state.currentMode == AppMode.sceneDescription
                    ? state.lastDescription
                    : state.lastNavigation,
                style: TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIdleContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.touch_app, size: 80, color: Colors.white),
          SizedBox(height: 20),
          Text(
            'READY',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Swipe to start',
            style: TextStyle(color: Colors.cyan, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildPausedContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pause_circle_outline, size: 80, color: Colors.orange),
          SizedBox(height: 20),
          Text(
            'PAUSED',
            style: TextStyle(
              color: Colors.orange,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Swipe down to resume',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls(AppState state) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        border: Border(top: BorderSide(color: Colors.white, width: 2)),
      ),
      child: SizedBox(height: 20), // Empty space to maintain layout
    );
  }

  Widget _buildErrorOverlay(AppState state) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.red.withValues(alpha: 0.9),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.white),
            SizedBox(height: 20),
            Text(
              'ERROR',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              state.errorMessage,
              style: TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusText(AppState state) {
    switch (state.status) {
      case AppStatus.initializing:
        return 'INITIALIZING...';
      case AppStatus.requestingPermissions:
        return 'REQUESTING PERMISSIONS...';
      case AppStatus.startingCamera:
        return 'STARTING CAMERA...';
      case AppStatus.idle:
        return 'READY';
      case AppStatus.ready:
        return 'READY';
      case AppStatus.paused:
        return 'PAUSED';
      case AppStatus.error:
        return 'ERROR';
    }
  }

  String _getModeText(AppMode mode) {
    switch (mode) {
      case AppMode.sceneDescription:
        return 'SCENE DESCRIPTION MODE';
      case AppMode.navigation:
        return 'NAVIGATION MODE';
    }
  }

  // Enhanced gesture handling for full-screen recognition
  Offset? _panStartPosition;
  Offset? _panCurrentPosition;
  bool _isGestureActive = false;

  void _handlePanStart(DragStartDetails details) {
    _panStartPosition = details.localPosition;
    _panCurrentPosition = details.localPosition;
    _isGestureActive = true;
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (!_isGestureActive) return;

    _panCurrentPosition = details.localPosition;
  }

  void _handlePanEnd(DragEndDetails details) {
    if (_panStartPosition == null || !_isGestureActive) return;

    final delta = details.velocity.pixelsPerSecond;
    final appStateProvider = context.read<AppStateProvider>();
    final state = appStateProvider.state;

    // Calculate distance moved
    final distance = details.velocity.pixelsPerSecond.distance;

    debugPrint(
      'Swipe detected - Velocity: dx=${delta.dx}, dy=${delta.dy}, Distance: $distance',
    );
    debugPrint('Current status: ${state.status}');

    // Allow gestures in more states - only block during initialization/error
    if (state.status == AppStatus.initializing ||
        state.status == AppStatus.requestingPermissions ||
        state.status == AppStatus.startingCamera ||
        state.status == AppStatus.error) {
      debugPrint('Swipe ignored - status not ready: ${state.status}');
      _resetGesture();
      return;
    }

    // More lenient minimum distance for better accessibility
    if (distance < 50) {
      debugPrint('❌ Swipe too short - distance: $distance');
      _resetGesture();
      return;
    }

    // Enhanced gesture detection with better thresholds
    final absDx = delta.dx.abs();
    final absDy = delta.dy.abs();

    debugPrint(
      'Swipe detected - dx: ${delta.dx}, dy: ${delta.dy}, absDx: $absDx, absDy: $absDy',
    );

    // More responsive direction detection
    final isHorizontal = absDx > absDy * 1.2;
    final isVertical = absDy > absDx * 1.2;

    debugPrint('Direction - Horizontal: $isHorizontal, Vertical: $isVertical');

    // Horizontal swipes (left/right)
    if (isHorizontal && absDx > 100) {
      if (delta.dx < 0) {
        // Swipe left - Scene Description
        debugPrint('✅ Swiping left - Scene Description');
        HapticFeedback.mediumImpact();
        appStateProvider.switchToSceneDescription();
      } else {
        // Swipe right - Navigation
        debugPrint('✅ Swiping right - Navigation');
        HapticFeedback.mediumImpact();
        appStateProvider.switchToNavigation();
      }
    }
    // Vertical swipes (up/down)
    else if (isVertical && absDy > 100) {
      if (delta.dy < 0) {
        // Swipe up - Exit
        debugPrint('✅ Swiping up - Exit');
        HapticFeedback.heavyImpact();
        appStateProvider.exitApp();
      } else {
        // Swipe down - Pause/Resume
        debugPrint('✅ Swiping down - Pause/Resume');
        HapticFeedback.lightImpact();
        appStateProvider.togglePause();
      }
    } else {
      debugPrint('❌ Swipe not recognized - dx: $absDx, dy: $absDy');
    }

    _resetGesture();
  }

  void _resetGesture() {
    _panStartPosition = null;
    _panCurrentPosition = null;
    _isGestureActive = false;
  }
}

enum AppMode { sceneDescription, navigation }

enum AppStatus {
  initializing,
  requestingPermissions,
  startingCamera,
  idle,
  ready,
  paused,
  error,
}

class AppState {
  final AppMode currentMode;
  final AppStatus status;
  final bool isCameraActive;
  final bool isCapturing;
  final String lastDescription;
  final String lastNavigation;
  final bool hasError;
  final String errorMessage;

  AppState({
    this.currentMode = AppMode.navigation,
    this.status = AppStatus.initializing,
    this.isCameraActive = false,
    this.isCapturing = false,
    this.lastDescription = '',
    this.lastNavigation = '',
    this.hasError = false,
    this.errorMessage = '',
  });

  AppState copyWith({
    AppMode? currentMode,
    AppStatus? status,
    bool? isCameraActive,
    bool? isCapturing,
    String? lastDescription,
    String? lastNavigation,
    bool? hasError,
    String? errorMessage,
  }) {
    return AppState(
      currentMode: currentMode ?? this.currentMode,
      status: status ?? this.status,
      isCameraActive: isCameraActive ?? this.isCameraActive,
      isCapturing: isCapturing ?? this.isCapturing,
      lastDescription: lastDescription ?? this.lastDescription,
      lastNavigation: lastNavigation ?? this.lastNavigation,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  String toString() {
    return 'AppState(currentMode: $currentMode, status: $status, isCameraActive: $isCameraActive, isCapturing: $isCapturing, hasError: $hasError)';
  }
}

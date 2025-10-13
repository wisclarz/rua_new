// lib/config/app_constants.dart
// App-wide constants for better maintainability and performance

class AppConstants {
  AppConstants._(); // Private constructor to prevent instantiation

  // ⚡ Animation Durations - Ultra-optimized for 60/120Hz screens (faster = smoother!)
  static const Duration animationFast = Duration(milliseconds: 120); // Optimized: 150→120ms
  static const Duration animationNormal = Duration(milliseconds: 200); // Optimized: 250→200ms
  static const Duration animationSlow = Duration(milliseconds: 300); // Optimized: 400→300ms
  static const Duration animationVerySlow = Duration(milliseconds: 450); // Optimized: 600→450ms
  
  // Animation delays
  static const Duration delayShort = Duration(milliseconds: 50);
  static const Duration delayNormal = Duration(milliseconds: 100);
  static const Duration delayLong = Duration(milliseconds: 200);
  
  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 12.0;
  static const double spacingL = 16.0;
  static const double spacingXL = 20.0;
  static const double spacingXXL = 24.0;
  static const double spacingXXXL = 32.0;
  
  // Border Radius
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 20.0;
  static const double radiusXXL = 24.0;
  
  // Icon Sizes
  static const double iconS = 16.0;
  static const double iconM = 20.0;
  static const double iconL = 24.0;
  static const double iconXL = 28.0;
  static const double iconXXL = 32.0;
  
  // Component Sizes
  static const double buttonHeight = 56.0;
  static const double buttonHeightSmall = 44.0;
  static const double fabSize = 76.0;
  static const double fabIconSize = 32.0;
  static const double navBarHeight = 56.0;
  static const double avatarSize = 56.0;
  static const double notificationButtonSize = 44.0;
  
  // Recording Visualization
  static const double recordingVisualizationSize = 240.0;
  static const double recordingMainButtonSize = 80.0;
  static const double recordingSideButtonSize = 60.0;
  static const double recordingIconSize = 36.0;
  static const double recordingSideIconSize = 28.0;
  
  // Day Indicator
  static const double dayIndicatorSize = 36.0;
  static const double dayIndicatorFontSize = 13.0;
  
  // Stat Card
  static const double statIconContainerSize = 40.0;
  static const double statIconSize = 22.0;
  
  // Cloud Animation (DreamyBackground)
  static const int cloudCount = 10;
  static const double cloudOpacityBaseDark = 0.18;
  static const double cloudOpacityBaseLight = 0.28;
  static const double cloudOpacityStep = 0.015;
  
  // Text Constraints
  static const int minDreamTextLength = 20;
  static const int maxDreamsToLoad = 50;
  
  // Audio Recording
  static const int audioBitRate = 128000;
  static const double audioSampleRate = 44100;
  static const int audioChannels = 1;
  static const int minAudioFileSize = 1000; // bytes
  
  // Animation repeat intervals (ms)
  static const int shimmerDuration = 2000;
  static const int pulseDuration = 3000;
  static const int breathingDuration = 1800;
  
  // Opacity values
  static const double opacityDisabled = 0.38;
  static const double opacityMedium = 0.6;
  static const double opacityHigh = 0.87;
  
  // Elevation
  static const double elevationLow = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationHigh = 8.0;
  
  // Blur
  static const double blurSigma = 10.0;
  
  // Border Width
  static const double borderThin = 1.0;
  static const double borderNormal = 1.5;
  static const double borderThick = 2.0;
  static const double borderExtraThick = 2.5;
}


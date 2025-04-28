import 'package:flutter/material.dart';

/// UI constants for consistent styling across the app
class UIConstants {
  // Spacing
  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 32.0;
  
  // Border radius
  static const double borderRadiusS = 8.0;
  static const double borderRadiusM = 12.0;
  static const double borderRadiusL = 16.0;
  static const double borderRadiusXL = 20.0;
  static const double borderRadiusCircular = 50.0;
  
  // Animation durations
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationMedium = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
  
  // Snackbar durations
  static const Duration snackbarShort = Duration(seconds: 2);
  static const Duration snackbarMedium = Duration(seconds: 3);
  static const Duration snackbarLong = Duration(seconds: 4);
  
  // Elevation
  static const double elevationS = 2.0;
  static const double elevationM = 4.0;
  static const double elevationL = 8.0;
  
  // Icon sizes
  static const double iconSizeS = 16.0;
  static const double iconSizeM = 24.0;
  static const double iconSizeL = 32.0;
  static const double iconSizeXL = 48.0;
  
  // Text sizes
  static const double textSizeS = 12.0;
  static const double textSizeM = 14.0;
  static const double textSizeL = 16.0;
  static const double textSizeXL = 18.0;
  static const double textSizeXXL = 24.0;
  
  // Avatar sizes
  static const double avatarSizeS = 40.0;
  static const double avatarSizeM = 60.0;
  static const double avatarSizeL = 80.0;
  static const double avatarSizeXL = 100.0;
  
  // Card dimensions
  static const double cardWidth = double.infinity;
  static const double cardMaxWidth = 400.0;
  
  // Opacity
  static const double opacityDisabled = 0.5;
  static const double opacityLight = 0.2;
  static const double opacityMedium = 0.5;
  static const double opacityHigh = 0.8;
  
  // Shadows
  static List<BoxShadow> get shadowLight => [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 4,
      spreadRadius: 0,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> get shadowMedium => [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 8,
      spreadRadius: 1,
      offset: const Offset(0, 3),
    ),
  ];
  
  static List<BoxShadow> get shadowHeavy => [
    BoxShadow(
      color: Colors.black.withOpacity(0.2),
      blurRadius: 16,
      spreadRadius: 2,
      offset: const Offset(0, 4),
    ),
  ];
}
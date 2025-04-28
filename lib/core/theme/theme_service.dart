import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:vktinder/core/theme/theme_constants.dart';
import 'package:vktinder/core/utils/ui_constants.dart';

/// Service for managing app theme
class ThemeService extends GetxService {
  final _storage = GetStorage();
  final _themeKey = 'theme_mode';

  /// Get the current theme mode
  ThemeMode get themeMode {
    final savedTheme = _storage.read(_themeKey);
    switch (savedTheme) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  /// Save the theme mode
  Future<void> saveTheme(String theme) async {
    await _storage.write(_themeKey, theme);
    updateTheme(theme);
  }

  /// Update the theme mode
  void updateTheme(String theme) {
    switch (theme) {
      case 'light':
        Get.changeThemeMode(ThemeMode.light);
        break;
      case 'dark':
        Get.changeThemeMode(ThemeMode.dark);
        break;
      default:
        Get.changeThemeMode(ThemeMode.system);
        break;
    }
  }

  /// Light theme configuration
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primarySwatch: Colors.blue,
      scaffoldBackgroundColor: ThemeConstants.backgroundLight,
      colorScheme: ColorScheme.fromSeed(
        seedColor: ThemeConstants.primaryLight,
        brightness: Brightness.light,
        primary: ThemeConstants.primaryLight,
        error: ThemeConstants.errorLight,
        background: ThemeConstants.backgroundLight,
        surface: ThemeConstants.cardLight,
        onPrimary: Colors.white,
        onBackground: ThemeConstants.textPrimaryLight,
        onSurface: ThemeConstants.textPrimaryLight,
        onError: Colors.white,
      ),
      textTheme: TextTheme(
        headlineLarge: ThemeConstants.headlineLarge.copyWith(color: ThemeConstants.textPrimaryLight),
        headlineMedium: ThemeConstants.headlineMedium.copyWith(color: ThemeConstants.textPrimaryLight),
        headlineSmall: ThemeConstants.headlineSmall.copyWith(color: ThemeConstants.textPrimaryLight),
        titleLarge: ThemeConstants.titleLarge.copyWith(color: ThemeConstants.textPrimaryLight),
        titleMedium: ThemeConstants.titleMedium.copyWith(color: ThemeConstants.textPrimaryLight),
        titleSmall: ThemeConstants.titleSmall.copyWith(color: ThemeConstants.textPrimaryLight),
        bodyLarge: ThemeConstants.bodyLarge.copyWith(color: ThemeConstants.textPrimaryLight),
        bodyMedium: ThemeConstants.bodyMedium.copyWith(color: ThemeConstants.textPrimaryLight),
        bodySmall: ThemeConstants.bodySmall.copyWith(color: ThemeConstants.textSecondaryLight),
      ),
      cardTheme: CardTheme(
        color: ThemeConstants.cardLight,
        shadowColor: ThemeConstants.shadowLight,
        elevation: UIConstants.elevationM,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(UIConstants.borderRadiusL)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: ThemeConstants.cardLight,
        selectedItemColor: ThemeConstants.primaryLight,
        unselectedItemColor: ThemeConstants.textSecondaryLight,
        type: BottomNavigationBarType.fixed,
        elevation: UIConstants.elevationL,
        selectedLabelStyle: ThemeConstants.titleSmall,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ThemeConstants.primaryLight,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: UIConstants.paddingM, horizontal: UIConstants.paddingL),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(UIConstants.borderRadiusM)),
          elevation: UIConstants.elevationS,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ThemeConstants.backgroundLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UIConstants.borderRadiusM),
          borderSide: BorderSide(color: ThemeConstants.dividerLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UIConstants.borderRadiusM),
          borderSide: BorderSide(color: ThemeConstants.dividerLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UIConstants.borderRadiusM),
          borderSide: BorderSide(color: ThemeConstants.primaryLight, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: UIConstants.paddingM, vertical: UIConstants.paddingM),
      ),
      dividerTheme: DividerThemeData(
        color: ThemeConstants.dividerLight,
        thickness: 1,
        space: UIConstants.paddingM,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ThemeConstants.cardLight,
        contentTextStyle: ThemeConstants.bodyMedium.copyWith(color: ThemeConstants.textPrimaryLight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(UIConstants.borderRadiusM)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Dark theme configuration
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primarySwatch: Colors.blue,
      scaffoldBackgroundColor: ThemeConstants.backgroundDark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: ThemeConstants.primaryDark,
        brightness: Brightness.dark,
        primary: ThemeConstants.primaryDark,
        error: ThemeConstants.errorDark,
        background: ThemeConstants.backgroundDark,
        surface: ThemeConstants.cardDark,
        onPrimary: Colors.white,
        onBackground: ThemeConstants.textPrimaryDark,
        onSurface: ThemeConstants.textPrimaryDark,
        onError: Colors.white,
      ),
      textTheme: TextTheme(
        headlineLarge: ThemeConstants.headlineLarge.copyWith(color: ThemeConstants.textPrimaryDark),
        headlineMedium: ThemeConstants.headlineMedium.copyWith(color: ThemeConstants.textPrimaryDark),
        headlineSmall: ThemeConstants.headlineSmall.copyWith(color: ThemeConstants.textPrimaryDark),
        titleLarge: ThemeConstants.titleLarge.copyWith(color: ThemeConstants.textPrimaryDark),
        titleMedium: ThemeConstants.titleMedium.copyWith(color: ThemeConstants.textPrimaryDark),
        titleSmall: ThemeConstants.titleSmall.copyWith(color: ThemeConstants.textPrimaryDark),
        bodyLarge: ThemeConstants.bodyLarge.copyWith(color: ThemeConstants.textPrimaryDark),
        bodyMedium: ThemeConstants.bodyMedium.copyWith(color: ThemeConstants.textPrimaryDark),
        bodySmall: ThemeConstants.bodySmall.copyWith(color: ThemeConstants.textSecondaryDark),
      ),
      cardTheme: CardTheme(
        color: ThemeConstants.cardDark,
        shadowColor: ThemeConstants.shadowDark,
        elevation: UIConstants.elevationM,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(UIConstants.borderRadiusL)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: ThemeConstants.cardDark,
        selectedItemColor: ThemeConstants.primaryDark,
        unselectedItemColor: ThemeConstants.textSecondaryDark,
        type: BottomNavigationBarType.fixed,
        elevation: UIConstants.elevationL,
        selectedLabelStyle: ThemeConstants.titleSmall,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ThemeConstants.primaryDark,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: UIConstants.paddingM, horizontal: UIConstants.paddingL),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(UIConstants.borderRadiusM)),
          elevation: UIConstants.elevationS,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UIConstants.borderRadiusM),
          borderSide: BorderSide(color: ThemeConstants.dividerDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UIConstants.borderRadiusM),
          borderSide: BorderSide(color: ThemeConstants.dividerDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UIConstants.borderRadiusM),
          borderSide: BorderSide(color: ThemeConstants.primaryDark, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: UIConstants.paddingM, vertical: UIConstants.paddingM),
      ),
      dividerTheme: DividerThemeData(
        color: ThemeConstants.dividerDark,
        thickness: 1,
        space: UIConstants.paddingM,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ThemeConstants.cardDark,
        contentTextStyle: ThemeConstants.bodyMedium.copyWith(color: ThemeConstants.textPrimaryDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(UIConstants.borderRadiusM)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

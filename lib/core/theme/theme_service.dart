import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ThemeService extends GetxService {
  final _storage = GetStorage();
  final _themeKey = 'theme_mode';
  final _themeMode = ThemeMode.system.obs;
  
  ThemeMode get themeMode => _themeMode.value;

  @override
  void onInit() {
    super.onInit();
    final savedTheme = _storage.read(_themeKey);
    updateTheme(savedTheme ?? 'system');
  }

  Future<void> saveTheme(String theme) async {
    await _storage.write(_themeKey, theme);
    updateTheme(theme);
  }

  void updateTheme(String theme) {
    switch (theme) {
      case 'light':
        _themeMode.value = ThemeMode.light;
        Get.changeThemeMode(ThemeMode.light);
        break;
      case 'dark':
        _themeMode.value = ThemeMode.dark;
        Get.changeThemeMode(ThemeMode.dark);
        break;
      default:
        _themeMode.value = ThemeMode.system;
        Get.changeThemeMode(ThemeMode.system);
        break;
    }
  }
  
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primarySwatch: Colors.blue,
      scaffoldBackgroundColor: Colors.grey[100],
      cardTheme: CardTheme(
        color: Colors.white,
        shadowColor: Colors.grey[350],
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.blue,
        centerTitle: true,
        elevation: 2,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
  
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.blue,
      scaffoldBackgroundColor: Colors.grey[900],
      cardTheme: CardTheme(
        color: Colors.grey[850],
        shadowColor: Colors.black54,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey[850],
        centerTitle: true,
        elevation: 2,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.grey[850],
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey[500],
        type: BottomNavigationBarType.fixed,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[700],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
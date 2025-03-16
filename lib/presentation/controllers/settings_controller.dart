import 'dart:convert';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vktinder/utils/theme_service.dart';

class Settings {
  String vkToken;
  String defaultMessage;
  String selectedTheme;

  Settings({
    required this.vkToken,
    required this.defaultMessage,
    required this.selectedTheme,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'vkToken': vkToken,
      'defaultMessage': defaultMessage,
      'selectedTheme': selectedTheme,
    };
  }

  factory Settings.fromMap(Map<String, dynamic> map) {
    return Settings(
      vkToken: map['vkToken'] as String,
      defaultMessage: map['defaultMessage'] as String,
      selectedTheme: map['selectedTheme'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory Settings.fromJson(String source) =>
      Settings.fromMap(json.decode(source) as Map<String, dynamic>);
}

class SettingsController extends GetxController {
  static SettingsController get to => Get.find<SettingsController>();

  // Make this public so it can be observed from outside
  final settings = Settings(
    vkToken: '',
    defaultMessage: '',
    selectedTheme: 'system',
  ).obs;

  // Getters for individual properties
  String get vkToken => settings.value.vkToken;
  String get defaultMessage => settings.value.defaultMessage;
  String get selectedTheme => settings.value.selectedTheme;

  Future<SettingsController> init() async {
    final prefs = await SharedPreferences.getInstance();
    final vkToken = prefs.getString('vkToken') ?? '';
    final defaultMsg = prefs.getString('defaultMessage') ?? '';
    final selectedTheme = prefs.getString('selectedTheme') ?? 'system';

    settings.value = Settings(
      vkToken: vkToken,
      defaultMessage: defaultMsg,
      selectedTheme: selectedTheme,
    );

    // Initialize ThemeService with current theme
    ThemeService.to.updateTheme(selectedTheme);

    return this;
  }

  Future<void> save(String vkToken, String defaultMessage, String selectedTheme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('vkToken', vkToken);
    await prefs.setString('defaultMessage', defaultMessage);
    await prefs.setString('selectedTheme', selectedTheme);

    settings.value = Settings(
      vkToken: vkToken,
      defaultMessage: defaultMessage,
      selectedTheme: selectedTheme,
    );

    // Update theme if changed
    ThemeService.to.updateTheme(selectedTheme);
  }
}
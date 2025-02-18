// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  @override
  String toString() =>
      'Settings(vkToken: $vkToken, defaultMessage: $defaultMessage, selectedTheme: $selectedTheme)';

  @override
  bool operator ==(covariant Settings other) {
    if (identical(this, other)) return true;

    return other.vkToken == vkToken &&
        other.defaultMessage == defaultMessage &&
        other.selectedTheme == selectedTheme;
  }

  @override
  int get hashCode =>
      vkToken.hashCode ^ defaultMessage.hashCode ^ selectedTheme.hashCode;
}

/// By extending ChangeNotifier, SettingsController can trigger
/// rebuilds via notifyListeners() when settings are updated.
class SettingsController extends ChangeNotifier {
  late Settings settings;
  SettingsController({required this.settings});

  static Future<SettingsController> load() async {
    final prefs = await SharedPreferences.getInstance();
    final vkToken = prefs.getString('vkToken') ?? '';
    final defaultMsg = prefs.getString('defaultMessage') ?? '';
    final selectedTheme = prefs.getString('selectedTheme') ?? 'system';
    return SettingsController(
      settings: Settings(
        vkToken: vkToken,
        defaultMessage: defaultMsg,
        selectedTheme: selectedTheme,
      ),
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('vkToken', settings.vkToken);
    await prefs.setString('defaultMessage', settings.defaultMessage);
    await prefs.setString('selectedTheme', settings.selectedTheme);
    notifyListeners();
  }
}

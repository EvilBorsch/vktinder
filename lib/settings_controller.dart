import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages app settings including VK Token and theme selection.
class SettingsController extends ChangeNotifier {
  String _vkToken;
  String _defaultMessage;
  String _selectedTheme;

  /// Possible theme values: "system", "light", "dark"
  SettingsController({
    String vkToken = '',
    String defaultMessage = '',
    String selectedTheme = 'system',
  }) : _vkToken = vkToken,
       _defaultMessage = defaultMessage,
       _selectedTheme = selectedTheme;

  String get vkToken => _vkToken;
  set vkToken(String newValue) {
    if (_vkToken != newValue) {
      _vkToken = newValue;
      notifyListeners();
    }
  }

  String get defaultMessage => _defaultMessage;
  set defaultMessage(String newValue) {
    if (_defaultMessage != newValue) {
      _defaultMessage = newValue;
      // Not calling notifyListeners() here to avoid excessive rebuilds
    }
  }

  String get selectedTheme => _selectedTheme;
  set selectedTheme(String newValue) {
    if (_selectedTheme != newValue) {
      _selectedTheme = newValue;
      notifyListeners();
    }
  }

  static Future<SettingsController> load() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsController(
      vkToken: prefs.getString('vkToken') ?? '',
      defaultMessage: prefs.getString('defaultMessage') ?? '',
      selectedTheme: prefs.getString('selectedTheme') ?? 'system',
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('vkToken', _vkToken);
    await prefs.setString('defaultMessage', _defaultMessage);
    await prefs.setString('selectedTheme', _selectedTheme);
  }
}

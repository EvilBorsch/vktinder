import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// By extending ChangeNotifier, SettingsController can trigger
/// rebuilds via notifyListeners() when settings are updated.
class SettingsController extends ChangeNotifier {
  String _vkToken;
  String _defaultMessage;
  String _selectedTheme;

  SettingsController({
    String vkToken = '',
    String defaultMessage = '',
    String selectedTheme = 'system',
  }) : _vkToken = vkToken,
       _defaultMessage = defaultMessage,
       _selectedTheme = selectedTheme;

  String get vkToken => _vkToken;
  String get defaultMessage => _defaultMessage;

  /// "system", "light", or "dark"
  String get selectedTheme => _selectedTheme;

  /// Update values and notify listeners
  set vkToken(String newValue) {
    if (_vkToken != newValue) {
      _vkToken = newValue;
      notifyListeners();
    }
  }

  set defaultMessage(String newValue) {
    if (_defaultMessage != newValue) {
      _defaultMessage = newValue;
      notifyListeners();
    }
  }

  set selectedTheme(String newValue) {
    if (_selectedTheme != newValue) {
      _selectedTheme = newValue;
      notifyListeners();
    }
  }

  static Future<SettingsController> load() async {
    final prefs = await SharedPreferences.getInstance();
    final vkToken = prefs.getString('vkToken') ?? '';
    final defaultMsg = prefs.getString('defaultMessage') ?? '';
    final selectedTheme = prefs.getString('selectedTheme') ?? 'system';
    return SettingsController(
      vkToken: vkToken,
      defaultMessage: defaultMsg,
      selectedTheme: selectedTheme,
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('vkToken', _vkToken);
    await prefs.setString('defaultMessage', _defaultMessage);
    await prefs.setString('selectedTheme', _selectedTheme);
  }
}

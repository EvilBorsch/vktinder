import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vktinder/core/theme/theme_service.dart';
import 'package:vktinder/data/repositories/settings_repository_impl.dart';

class SettingsController extends GetxController {
  final SettingsRepository _settingsRepository = Get.find<SettingsRepository>();
  final ThemeService _themeService = Get.find<ThemeService>();

  // Observable settings
  final RxString _vkToken = ''.obs;
  final RxString _defaultMessage = ''.obs;
  final RxString _theme = 'system'.obs;

  // Observable to trigger reload after token change
  final RxInt tokenChange = 0.obs;

  // Getters for settings
  String get vkToken => _vkToken.value;

  String get defaultMessage => _defaultMessage.value;

  String get theme => _theme.value;

  @override
  void onInit() {
    super.onInit();
    loadSettings();
  }

  void loadSettings()  {
    final vkToken = _settingsRepository.getVkToken();
    final defaultMessage = _settingsRepository.getDefaultMessage();
    final theme = _settingsRepository.getTheme();

    _vkToken.value = vkToken;
    _defaultMessage.value = defaultMessage;
    _theme.value = theme;
  }

  Future<void> saveSettings({
    required String vkToken,
    required String defaultMessage,
    required String theme,
  }) async {
    // First update our reactive variables
    final bool tokenChanged = _vkToken.value != vkToken;

    _vkToken.value = vkToken;
    _defaultMessage.value = defaultMessage;
    _theme.value = theme;

    // Save to repository
    await _settingsRepository.saveSettings(
      vkToken: vkToken,
      defaultMessage: defaultMessage,
      theme: theme,
    );

    // Update theme immediately
    _themeService.updateTheme(theme);

    // Trigger reload if token changed
    if (tokenChanged) {
      tokenChange.value++;
    }

    Get.snackbar(
      'Успех',
      'Настройки успешно сохранены',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.green[100],
      colorText: Colors.green[900],
      margin: const EdgeInsets.all(8),
      borderRadius: 10,
      duration: const Duration(seconds: 2),
      icon: const Icon(Icons.check_circle, color: Colors.green),
    );
  }
}

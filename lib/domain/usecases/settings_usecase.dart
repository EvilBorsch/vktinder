import 'package:get/get.dart';
import 'package:vktinder/core/theme/theme_service.dart';
import 'package:vktinder/domain/repositories/settings_repository.dart';

class SettingsUsecase extends GetxService {
  final SettingsRepository _repository = Get.find<SettingsRepository>();
  final ThemeService _themeService = Get.find<ThemeService>();

  Future<Map<String, String>> getSettings() async {
    final vkToken = await _repository.getVkToken();
    final defaultMessage = await _repository.getDefaultMessage();
    final theme = await _repository.getTheme();

    return {
      'vkToken': vkToken,
      'defaultMessage': defaultMessage,
      'theme': theme,
    };
  }

  Future<void> saveSettings({
    required String vkToken,
    required String defaultMessage,
    required String theme,
  }) async {
    // Save settings to repository
    await _repository.saveSettings(
      vkToken: vkToken,
      defaultMessage: defaultMessage,
      theme: theme,
    );

    // Update theme immediately
    _themeService.updateTheme(theme);
  }
}
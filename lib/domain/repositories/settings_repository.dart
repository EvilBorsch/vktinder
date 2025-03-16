abstract class SettingsRepository {
  Future<String> getVkToken();
  Future<String> getDefaultMessage();
  Future<String> getTheme();

  Future<void> saveSettings({
    required String vkToken,
    required String defaultMessage,
    required String theme,
  });
}

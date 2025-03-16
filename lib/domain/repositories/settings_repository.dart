abstract class SettingsRepository {
  String getVkToken();
  String getDefaultMessage();
  String getTheme();
  
  Future<void> saveSettings({
    required String vkToken,
    required String defaultMessage,
    required String theme,
  });
}
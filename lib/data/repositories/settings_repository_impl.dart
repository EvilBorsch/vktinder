import 'package:get/get.dart';
import 'package:vktinder/data/providers/local_storage_provider.dart';

class SettingsRepository {
  final LocalStorageProvider _storageProvider =
      Get.find<LocalStorageProvider>();

  String getVkToken() {
    return _storageProvider.getVkToken();
  }

  String getDefaultMessage() {
    return _storageProvider.getDefaultMessage();
  }

  String getTheme() {
    return _storageProvider.getTheme();
  }

  Future<void> saveSettings({
    required String vkToken,
    required String defaultMessage,
    required String theme,
  }) async {
    await _storageProvider.saveVkToken(vkToken);
    await _storageProvider.saveDefaultMessage(defaultMessage);
    await _storageProvider.saveTheme(theme);
  }
}

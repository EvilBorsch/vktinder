import 'package:get/get.dart';
import 'package:vktinder/data/providers/local_storage_provider.dart';
import 'package:vktinder/domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final LocalStorageProvider _storageProvider = Get.find<LocalStorageProvider>();

  @override
  String getVkToken() {
    return _storageProvider.getVkToken();
  }

  @override
  String getDefaultMessage() {
    return _storageProvider.getDefaultMessage();
  }

  @override
  String getTheme() {
    return _storageProvider.getTheme();
  }

  @override
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
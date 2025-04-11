import 'package:get/get.dart';
import 'package:vktinder/data/providers/local_storage_provider.dart';

class SettingsRepository {
  final LocalStorageProvider _storageProvider =
  Get.find<LocalStorageProvider>();

  // Existing Getters
  String getVkToken() {
    return _storageProvider.getVkToken();
  }

  String getDefaultMessage() {
    return _storageProvider.getDefaultMessage();
  }

  String getTheme() {
    return _storageProvider.getTheme();
  }

  // --- NEW Getters ---
  List<String> getCities() {
    return _storageProvider.getCities();
  }

  (int?, int?) getAgeRange() {
    return _storageProvider.getAgeRange();
  }
  
  int getSexFilter() {
    return _storageProvider.getSexFilter();
  }
  
  bool getSkipClosedProfiles() {
    return _storageProvider.getSkipClosedProfiles();
  }

  List<String> getGroupUrls() {
    return _storageProvider.getGroupUrls();
  }

  // Updated Save Method
  Future<void> saveSettings({
    required String vkToken,
    required String defaultMessage,
    required String theme,
    // --- NEW Parameters ---
    required List<String> cities,
    required int? ageFrom,
    required int? ageTo,
    required int sexFilter,
    required List<String> groupUrls,
    required bool skipClosedProfiles,
  }) async {
    await Future.wait([
      _storageProvider.saveVkToken(vkToken),
      _storageProvider.saveDefaultMessage(defaultMessage),
      _storageProvider.saveTheme(theme),
      // --- NEW Saves ---
      _storageProvider.saveCities(cities),
      _storageProvider.saveAgeRange(ageFrom, ageTo),
      _storageProvider.saveSexFilter(sexFilter),
      _storageProvider.saveGroupUrls(groupUrls),
      _storageProvider.saveSkipClosedProfiles(skipClosedProfiles),
    ]);
  }
}

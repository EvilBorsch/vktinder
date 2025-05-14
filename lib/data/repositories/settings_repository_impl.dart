// --- File: lib/data/repositories/settings_repository_impl.dart ---
import 'package:get/get.dart';
import 'package:vktinder/data/models/vk_city_info.dart';
import 'package:vktinder/data/models/vk_group_info.dart';
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

  bool getShowClosedProfilesWithMessageAbility() {
    return _storageProvider.getShowClosedProfilesWithMessageAbility();
  }

  bool getSkipRelationFilter() { // Added getter
    return _storageProvider.getSkipRelationFilter();
  }

  List<String> getGroupUrls() {
    return _storageProvider.getGroupUrls();
  }

  List<VKGroupInfo> getGroupInfos() {
    final infos = _storageProvider.getGroupInfos();
    return infos.map((info) => VKGroupInfo.fromJson(info)).toList();
  }

  List<VKCityInfo> getCityInfos() {
    final infos = _storageProvider.getCityInfos();
    return infos.map((info) => VKCityInfo.fromJson(info)).toList();
  }

  // Updated Save Method
  Future<void> saveSettings({
    required String vkToken,
    required String defaultMessage,
    required String theme,
    // --- Parameters ---
    required List<String> cities,
    required int? ageFrom,
    required int? ageTo,
    required int sexFilter,
    required List<String> groupUrls,
    required List<VKGroupInfo> groupInfos,
    required List<VKCityInfo> cityInfos,
    required bool skipClosedProfiles,
    required bool showClosedProfilesWithMessageAbility,
    required bool skipRelationFilter,
  }) async {
    // Convert objects to JSON maps for storage
    final groupInfosJson = groupInfos.map((info) => info.toJson()).toList();
    final cityInfosJson = cityInfos.map((info) => info.toJson()).toList();

    await Future.wait([
      _storageProvider.saveVkToken(vkToken),
      _storageProvider.saveDefaultMessage(defaultMessage),
      _storageProvider.saveTheme(theme),
      _storageProvider.saveCities(cities),
      _storageProvider.saveAgeRange(ageFrom, ageTo),
      _storageProvider.saveSexFilter(sexFilter),
      _storageProvider.saveGroupUrls(groupUrls),
      _storageProvider.saveGroupInfos(groupInfosJson),
      _storageProvider.saveCityInfos(cityInfosJson),
      _storageProvider.saveSkipClosedProfiles(skipClosedProfiles),
      _storageProvider.saveShowClosedProfilesWithMessageAbility(showClosedProfilesWithMessageAbility),
      _storageProvider.saveSkipRelationFilter(skipRelationFilter),
    ]);
  }
}

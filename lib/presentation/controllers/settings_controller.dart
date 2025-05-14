// --- File: lib/presentation/controllers/settings_controller.dart ---
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vktinder/core/theme/theme_service.dart';
import 'package:vktinder/data/models/vk_city_info.dart';
import 'package:vktinder/data/models/vk_group_info.dart';
import 'package:vktinder/data/providers/vk_api_provider.dart';
import 'package:vktinder/data/repositories/settings_repository_impl.dart';

class SettingsController extends GetxController {
  TextEditingController? vkTokenController;
  TextEditingController? defaultMsgController;
  TextEditingController? citiesController;
  TextEditingController? ageFromController;
  TextEditingController? ageToController;
  TextEditingController? newGroupUrlController;

  final SettingsRepository _settingsRepository = Get.find<SettingsRepository>();
  final ThemeService _themeService = Get.find<ThemeService>();
  final VkApiProvider _apiProvider =
      Get.find<VkApiProvider>(); // Needed for validating group URLs

  // Observable settings
  final RxString _vkToken = ''.obs;
  final RxString _defaultMessage = ''.obs;
  final RxString _theme = 'system'.obs;

  // --- Observables ---
  final RxList<String> cities = <String>[].obs;
  final RxnInt ageFrom = RxnInt(); // Use RxnInt for nullable int
  final RxnInt ageTo = RxnInt(); // Use RxnInt for nullable int
  final RxInt sexFilter = 0.obs; // 0 = any, 1 = female, 2 = male
  final RxList<String> groupUrls =
      <String>[].obs; // Store URLs as entered by user
  final RxList<VKGroupInfo> groupInfos =
      <VKGroupInfo>[].obs; // Store resolved group info
  final RxList<VKCityInfo> cityInfos =
      <VKCityInfo>[].obs; // Store resolved city info
  final RxBool skipClosedProfiles =
      true.obs; // Skip users with closed profiles - Default TRUE
  final RxBool showClosedProfilesWithMessageAbility =
      false.obs; // Show closed profiles with message ability - Default FALSE
  final RxBool skipRelationFilter =
      true.obs; // Skip users with specific relations - Default TRUE

  // UI State
  final RxBool isGroupUrlValidating = false.obs;

  // Observable to trigger reload after token OR filter change
  final RxInt settingsChanged =
      0.obs; // Use a single signal for any relevant change

  // Getters for settings
  String get vkToken => _vkToken.value;

  String get defaultMessage => _defaultMessage.value;

  String get theme => _theme.value;

  RxString get themeRx => _theme;

  @override
  void onInit() {
    super.onInit();
    loadSettings();
  }

  // Helper to save group infos to disk
  void _saveGroupInfosToDisk() {
    try {
      _settingsRepository.saveSettings(
        vkToken: _vkToken.value,
        defaultMessage: _defaultMessage.value,
        theme: _theme.value,
        cities: cities.toList(),
        ageFrom: ageFrom.value,
        ageTo: ageTo.value,
        sexFilter: sexFilter.value,
        groupUrls: groupUrls.toList(),
        groupInfos: groupInfos.toList(),
        cityInfos: cityInfos.toList(),
        skipClosedProfiles: skipClosedProfiles.value,
        showClosedProfilesWithMessageAbility: showClosedProfilesWithMessageAbility.value,
        skipRelationFilter: skipRelationFilter.value,
      );
    } catch (e) {
      print("Error saving group infos to disk: $e");
    }
  }

  @override
  void onClose() {
    // Dispose text controllers
    vkTokenController?.dispose();
    defaultMsgController?.dispose();
    citiesController?.dispose();
    ageFromController?.dispose();
    ageToController?.dispose();
    newGroupUrlController?.dispose();
    super.onClose();
  }

  void loadSettings() {
    _vkToken.value = _settingsRepository.getVkToken();
    _defaultMessage.value = _settingsRepository.getDefaultMessage();
    _theme.value = _settingsRepository.getTheme();

    cities.clear();
    cities.addAll(_settingsRepository.getCities());
    final (from, to) = _settingsRepository.getAgeRange();
    ageFrom.value = from;
    ageTo.value = to;
    sexFilter.value = _settingsRepository.getSexFilter();
    groupUrls.assignAll(_settingsRepository.getGroupUrls());
    skipClosedProfiles.value = _settingsRepository.getSkipClosedProfiles();
    showClosedProfilesWithMessageAbility.value = _settingsRepository.getShowClosedProfilesWithMessageAbility();
    skipRelationFilter.value = _settingsRepository.getSkipRelationFilter();

    // Load resolved infos
    groupInfos.assignAll(_settingsRepository.getGroupInfos());
    cityInfos.assignAll(_settingsRepository.getCityInfos());

    // Re-initialize controllers after loading
    vkTokenController = TextEditingController(text: _vkToken.value);
    defaultMsgController = TextEditingController(text: _defaultMessage.value);
    citiesController = TextEditingController(text: cities.join(', '));
    ageFromController =
        TextEditingController(text: ageFrom.value?.toString() ?? '');
    ageToController =
        TextEditingController(text: ageTo.value?.toString() ?? '');
    newGroupUrlController = TextEditingController(); // Always start empty

    update(); // Force update if needed for non-reactive UI elements relying on controllers
  }

  // --- Methods to modify settings reactively (mostly used by saveSettings now) ---

  // Add/Remove Group URLs
  // Helper method to get group info by URL from storage
  VKGroupInfo? getGroupInfoByUrl(String url) {
    return groupInfos.firstWhereOrNull((info) => info.sourceUrl == url);
  }

  // Helper method to find a city info by name
  VKCityInfo? getCityInfoByName(String cityName) {
    final normalized = cityName.trim().toLowerCase();
    return cityInfos
        .firstWhereOrNull((info) => info.name.toLowerCase() == normalized);
  }

  Future<void> addGroupUrl(String url) async {
    final trimmedUrl = url.trim();
    if (trimmedUrl.isEmpty) {
      Get.snackbar(
        'Информация',
        'Введите URL или короткое имя группы.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(8),
      );
      return;
    }

    // Simple check for duplicates before API call
    if (groupUrls.any((existing) =>
        existing.trim().toLowerCase() == trimmedUrl.toLowerCase())) {
      Get.snackbar(
        'Информация',
        'Эта группа уже добавлена.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(8),
      );
      return;
    }

    // Validate against VK API before adding
    isGroupUrlValidating.value = true;
    try {
      final groupInfo =
          await _apiProvider.getGroupInfoByScreenName(vkToken, trimmedUrl);
      if (groupInfo != null) {
        // Check if ID is already present via another URL/name
        bool idExists = groupInfos.any((g) => g.id == groupInfo.id);

        if (idExists) {
          Get.snackbar(
            'Информация',
            'Группа "${groupInfo.name}" (ID: ${groupInfo.id}) уже есть в списке (возможно, под другим адресом).',
            snackPosition: SnackPosition.BOTTOM,
            margin: const EdgeInsets.all(8),
          );
        } else {
          groupUrls.add(trimmedUrl); // Add the original URL/name
          groupInfos.add(groupInfo); // Store the resolved group info

          // Save the group info to disk immediately
          _saveGroupInfosToDisk();

          Get.snackbar(
            'Успех',
            'Группа "${groupInfo.name}" добавлена. Не забудьте сохранить настройки.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green[100],
            colorText: Colors.green[900],
            margin: const EdgeInsets.all(8),
            duration: const Duration(seconds: 2),
          );
        }
      } else {
        Get.snackbar(
          'Ошибка',
          'Не удалось найти группу по адресу "$trimmedUrl". Проверьте URL/имя и токен.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange[100],
          colorText: Colors.orange[900],
          margin: const EdgeInsets.all(8),
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Ошибка API',
        'Не удалось проверить группу: ${e.toString().contains("vk_api_provider.dart") ? e.toString().split(':').last.trim() : e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
        margin: const EdgeInsets.all(8),
        duration: const Duration(seconds: 4),
      );
    } finally {
      isGroupUrlValidating.value = false;
    }
  }

  void removeGroupUrl(String url) {
    // Get the group info before removing it
    final groupInfo = getGroupInfoByUrl(url);
    final displayName = groupInfo?.name ?? url;

    groupUrls.remove(url);

    // Also remove the corresponding group info
    groupInfos.removeWhere((info) => info.sourceUrl == url);

    // Save the changes to disk immediately
    _saveGroupInfosToDisk();

    Get.snackbar(
      'Удалено',
      'Группа "$displayName" удалена из списка. Не забудьте сохранить настройки.',
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(8),
      duration: const Duration(seconds: 2),
    );
  }

  // Method to resolve city names to city IDs
  Future<void> resolveCityNames(List<String> cityNames) async {
    if (vkToken.isEmpty || cityNames.isEmpty) return;

    // Clear existing city info entries that aren't in the new list
    cityInfos.removeWhere((info) => !cityNames
        .any((name) => name.trim().toLowerCase() == info.name.toLowerCase()));

    // Filter out cities that already have info
    final unresolved = cityNames
        .where((name) => !cityInfos.any(
            (info) => info.name.toLowerCase() == name.trim().toLowerCase()))
        .toList();

    if (unresolved.isEmpty) return; // All cities already resolved

    try {
      final cityIdMap =
          await _apiProvider.getCityIdsByNames(vkToken, unresolved);

      // Add resolved cities to cityInfos
      cityIdMap.forEach((name, id) {
        if (!cityInfos.any((info) => info.id == id)) {
          cityInfos.add(VKCityInfo(id: id, name: name));
        }
      });
    } catch (e) {
      print("Error resolving city names: $e");
      // Don't show a snackbar here as it's part of the save process
    }
  }

  // Updated Save Method
  Future<void> saveSettings({
    required String vkToken,
    required String defaultMessage,
    required String theme,
    required List<String> currentCities,
    required String? ageFromString,
    required String? ageToString,
    required int sexFilter,
    required List<String> currentGroupUrls,
    required bool skipClosedProfiles,
    required bool showClosedProfilesWithMessageAbility,
    required bool skipRelationFilter,
  }) async {
    // Validate and parse age
    final parsedAgeFrom = (ageFromString != null && ageFromString.isNotEmpty)
        ? int.tryParse(ageFromString)
        : null;
    final parsedAgeTo = (ageToString != null && ageToString.isNotEmpty)
        ? int.tryParse(ageToString)
        : null;

    // Basic validation (e.g., ageFrom <= ageTo)
    if (parsedAgeFrom != null &&
        parsedAgeTo != null &&
        parsedAgeFrom > parsedAgeTo) {
      Get.snackbar(
        'Ошибка валидации',
        'Возраст "От" не может быть больше возраста "До".',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange[100],
        colorText: Colors.orange[900],
        margin: const EdgeInsets.all(8),
        duration: const Duration(seconds: 3),
      );
      return; // Don't save invalid range
    }

    // Check if filters actually changed
    final bool filtersChanged = _vkToken.value != vkToken ||
        !listEquals(cities, currentCities) ||
        ageFrom.value != parsedAgeFrom ||
        ageTo.value != parsedAgeTo ||
        this.sexFilter.value != sexFilter ||
        !listEquals(groupUrls, currentGroupUrls) ||
        this.skipClosedProfiles.value != skipClosedProfiles ||
        this.showClosedProfilesWithMessageAbility.value != showClosedProfilesWithMessageAbility ||
        this.skipRelationFilter.value != skipRelationFilter;

    // Update reactive variables
    _vkToken.value = vkToken;
    _defaultMessage.value = defaultMessage;
    _theme.value = theme;
    cities.assignAll(currentCities);
    groupUrls.assignAll(currentGroupUrls);
    ageFrom.value = parsedAgeFrom;
    ageTo.value = parsedAgeTo;
    this.sexFilter.value = sexFilter;
    this.skipClosedProfiles.value = skipClosedProfiles;
    this.showClosedProfilesWithMessageAbility.value = showClosedProfilesWithMessageAbility;
    this.skipRelationFilter.value = skipRelationFilter;

    // 1. Resolve group URLs and update groupInfos if needed
    List<Future<void>> resolutionTasks = [];
    for (final url in currentGroupUrls) {
      if (!groupInfos.any((info) => info.sourceUrl == url)) {
        // Try to resolve any URLs that don't have info yet
        resolutionTasks.add(_resolveAndAddGroupInfo(url));
      }
    }

    // 2. Resolve city names to IDs
    resolutionTasks.add(resolveCityNames(currentCities));

    // Wait for all resolutions to complete
    if (resolutionTasks.isNotEmpty) {
      await Future.wait(resolutionTasks);
    }

    try {
      // 3. Save to repository with all resolved data
      await _settingsRepository.saveSettings(
        vkToken: _vkToken.value,
        defaultMessage: _defaultMessage.value,
        theme: _theme.value,
        cities: this.cities.toList(),
        ageFrom: this.ageFrom.value,
        ageTo: this.ageTo.value,
        sexFilter: this.sexFilter.value,
        groupUrls: this.groupUrls.toList(),
        groupInfos: this.groupInfos.toList(),
        cityInfos: this.cityInfos.toList(),
        skipClosedProfiles: this.skipClosedProfiles.value,
        showClosedProfilesWithMessageAbility: this.showClosedProfilesWithMessageAbility.value,
        skipRelationFilter: this.skipRelationFilter.value,
      );

      // Update theme immediately
      _themeService.saveTheme(theme);

      // Trigger reload only if relevant filters changed
      if (filtersChanged) {
        settingsChanged.value++;
        print("Settings relevant to user search changed. Triggering update.");
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
    } catch (e) {
      Get.snackbar(
        'Ошибка сохранения',
        'Не удалось сохранить настройки: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
        margin: const EdgeInsets.all(8),
        borderRadius: 10,
        duration: const Duration(seconds: 4),
      );
    }
  }

  // Helper to resolve and add a group info
  Future<void> _resolveAndAddGroupInfo(String url) async {
    try {
      final groupInfo =
          await _apiProvider.getGroupInfoByScreenName(vkToken, url);
      if (groupInfo != null) {
        // Remove any existing info for this URL
        groupInfos.removeWhere((info) => info.sourceUrl == url);
        // Add the new info
        groupInfos.add(groupInfo);
      }
    } catch (e) {
      print("Error resolving group URL $url: $e");
      // We don't show a snackbar here as this is part of the save process
    }
  }

  // Helper for list equality check using collection package for better safety
  bool listEquals<T>(List<T> a, List<T> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

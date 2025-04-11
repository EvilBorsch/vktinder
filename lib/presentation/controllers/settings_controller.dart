import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vktinder/core/theme/theme_service.dart';
import 'package:vktinder/data/providers/vk_api_provider.dart'; // Import API provider for group validation
import 'package:vktinder/data/repositories/settings_repository_impl.dart';

import '../../data/models/vk_group_info.dart';

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
  // --- NEW Observables ---
  final RxList<String> cities = <String>[].obs;
  final RxnInt ageFrom = RxnInt(); // Use RxnInt for nullable int
  final RxnInt ageTo = RxnInt(); // Use RxnInt for nullable int
  final RxInt sexFilter = 0.obs; // 0 = any, 1 = female, 2 = male
  final RxList<String> groupUrls =
      <String>[].obs; // Store URLs as entered by user
  final RxBool skipClosedProfiles = false.obs; // Skip users with closed profiles

  // UI State
  final RxBool isGroupUrlValidating = false.obs;

  // Observable to trigger reload after token OR filter change
  final RxInt settingsChanged =
      0.obs; // Use a single signal for any relevant change

  // Getters for settings
  String get vkToken => _vkToken.value;
  String get defaultMessage => _defaultMessage.value;
  String get theme => _theme.value;

  @override
  void onInit() {
    super.onInit();
    loadSettings();
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
    // --- NEW Loads ---
    cities.clear();
    cities.addAll(_settingsRepository.getCities());
    final (from, to) = _settingsRepository.getAgeRange();
    ageFrom.value = from;
    ageTo.value = to;
    sexFilter.value = _settingsRepository.getSexFilter();
    groupUrls.assignAll(_settingsRepository.getGroupUrls());
    skipClosedProfiles.value = _settingsRepository.getSkipClosedProfiles();
  }

  // --- Methods to modify settings reactively ---

  void addCity(String cityName) {
    final trimmed = cityName.trim();
    if (trimmed.isNotEmpty && !cities.contains(trimmed)) {
      cities.add(trimmed);
    }
  }

  void removeCity(String cityName) {
    cities.remove(cityName);
  }

  void setAgeFrom(String value) {
    final intValue = int.tryParse(value);
    if (value.isEmpty) {
      ageFrom.value = null; // Allow clearing
    } else if (intValue != null && intValue >= 14) {
      // VK min age is often 14
      ageFrom.value = intValue;
    }
  }

  void setAgeTo(String value) {
    final intValue = int.tryParse(value);
    if (value.isEmpty) {
      ageTo.value = null; // Allow clearing
    } else if (intValue != null && intValue > 0) {
      ageTo.value = intValue;
    }
  }

  // Add/Remove Group URLs
  Future<void> addGroupUrl(String url) async {
    final trimmedUrl = url.trim();
    if (trimmedUrl.isEmpty || groupUrls.contains(trimmedUrl)) {
      Get.snackbar(
        'Информация',
        trimmedUrl.isEmpty
            ? 'Введите URL или короткое имя группы.'
            : 'Эта группа уже добавлена.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(8),
      );
      return;
    }

    // Basic check if it looks like a URL or screen name
    if (!trimmedUrl.startsWith('http') &&
        !RegExp(r'^[a-zA-Z0-9_.]+$').hasMatch(trimmedUrl)) {
      Get.snackbar(
        'Ошибка',
        'Неверный формат URL или короткого имени.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
        margin: const EdgeInsets.all(8),
      );
      return;
    }

    // Optional: Validate against VK API before adding
    isGroupUrlValidating.value = true;
    try {
      final groupInfo =
          await _apiProvider.getGroupInfoByScreenName(vkToken, trimmedUrl);
      if (groupInfo != null) {
        // Check if ID is already present via another URL/name (optional but good)
        bool idExists = false;
        List<Future<VKGroupInfo?>> checkFutures = [];
        for (var existingUrl in groupUrls) {
          checkFutures
              .add(_apiProvider.getGroupInfoByScreenName(vkToken, existingUrl));
        }
        final existingInfos = await Future.wait(checkFutures);
        if (existingInfos
            .whereType<VKGroupInfo>()
            .any((g) => g.id == groupInfo.id)) {
          Get.snackbar(
            'Информация',
            'Группа "${groupInfo.name}" уже есть в списке (возможно, под другим адресом).',
            snackPosition: SnackPosition.BOTTOM,
            margin: const EdgeInsets.all(8),
          );
        } else {
          groupUrls.add(trimmedUrl); // Add the original URL/name
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
        'Не удалось проверить группу: ${e.toString()}',
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
    groupUrls.remove(url);
    Get.snackbar(
      'Удалено',
      'Группа "$url" удалена из списка. Не забудьте сохранить настройки.',
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(8),
      duration: const Duration(seconds: 2),
    );
  }

  // --- Updated Save Method ---
  Future<void> saveSettings({
    required String vkToken,
    required String defaultMessage,
    required String theme,
    // Read from UI controllers/Rx vars for new fields
    required List<String> currentCities,
    required String? ageFromString,
    required String? ageToString,
    required int sexFilter,
    required List<String> currentGroupUrls,
    bool? skipClosedProfiles,
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

    // First update our reactive variables
    final bool filtersChanged = _vkToken.value != vkToken ||
        !listEquals(cities, currentCities) ||
        ageFrom.value != parsedAgeFrom ||
        ageTo.value != parsedAgeTo ||
        this.sexFilter.value != sexFilter ||
        !listEquals(groupUrls, currentGroupUrls) ||
        this.skipClosedProfiles.value != (skipClosedProfiles ?? this.skipClosedProfiles.value);

    _vkToken.value = vkToken;
    _defaultMessage.value = defaultMessage;
    _theme.value = theme;

    // Clear and add items individually to ensure proper reactivity
    cities.clear();
    cities.addAll(currentCities);

    ageFrom.value = parsedAgeFrom;
    ageTo.value = parsedAgeTo;
    this.sexFilter.value = sexFilter;

    // Same for group URLs
    groupUrls.clear();
    groupUrls.addAll(currentGroupUrls);
    
    // Update skipClosedProfiles if provided
    if (skipClosedProfiles != null) {
      this.skipClosedProfiles.value = skipClosedProfiles;
    }

    // Save to repository
    await _settingsRepository.saveSettings(
      vkToken: vkToken,
      defaultMessage: defaultMessage,
      theme: theme,
      cities:
          currentCities, // Pass the parameter directly to ensure correct values
      ageFrom: parsedAgeFrom,
      ageTo: parsedAgeTo,
      sexFilter: sexFilter,
      groupUrls: currentGroupUrls, // Pass the parameter directly
      skipClosedProfiles: this.skipClosedProfiles.value,
    );

    // Update theme immediately
    _themeService.updateTheme(theme);

    // Trigger reload if token or filters changed
    if (filtersChanged) {
      settingsChanged
          .value++; // Increment to notify listeners (like HomeController)
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
  }

  // Helper for list equality check (or use collection package's listEquals)
  bool listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

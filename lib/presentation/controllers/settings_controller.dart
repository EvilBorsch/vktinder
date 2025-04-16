// --- File: lib/presentation/controllers/settings_controller.dart ---
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
  final RxBool skipClosedProfiles =
      true.obs; // Skip users with closed profiles - Default TRUE
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
    cities.clear(); // Use clear/addAll for reactivity if needed
    cities.addAll(_settingsRepository.getCities());
    final (from, to) = _settingsRepository.getAgeRange();
    ageFrom.value = from;
    ageTo.value = to;
    sexFilter.value = _settingsRepository.getSexFilter();
    groupUrls.assignAll(_settingsRepository.getGroupUrls());
    skipClosedProfiles.value = _settingsRepository.getSkipClosedProfiles();
    skipRelationFilter.value = _settingsRepository.getSkipRelationFilter(); // Load new setting

    // Re-initialize controllers after loading
    vkTokenController = TextEditingController(text: _vkToken.value);
    defaultMsgController = TextEditingController(text: _defaultMessage.value);
    citiesController = TextEditingController(text: cities.join(', '));
    ageFromController = TextEditingController(text: ageFrom.value?.toString() ?? '');
    ageToController = TextEditingController(text: ageTo.value?.toString() ?? '');
    newGroupUrlController = TextEditingController(); // Always start empty

    update(); // Force update if needed for non-reactive UI elements relying on controllers
  }

  // --- Methods to modify settings reactively (mostly used by saveSettings now) ---

  // Add/Remove Group URLs
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
    if (groupUrls.any((existing) => existing.trim().toLowerCase() == trimmedUrl.toLowerCase())) {
      Get.snackbar(
        'Информация',
        'Эта группа уже добавлена.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(8),
      );
      return;
    }


    // Basic check if it looks like a URL or screen name (Simplified, relies on API for full validation)
    // if (!trimmedUrl.startsWith('http') &&
    //     !RegExp(r'^[a-zA-Z0-9_.]+$').hasMatch(trimmedUrl)) {
    //   Get.snackbar(
    //     'Ошибка',
    //     'Неверный формат URL или короткого имени.',
    //     snackPosition: SnackPosition.BOTTOM,
    //     backgroundColor: Colors.red[100],
    //     colorText: Colors.red[900],
    //     margin: const EdgeInsets.all(8),
    //   );
    //   return;
    // }

    // Optional: Validate against VK API before adding
    isGroupUrlValidating.value = true;
    try {
      final groupInfo =
      await _apiProvider.getGroupInfoByScreenName(vkToken, trimmedUrl);
      if (groupInfo != null) {
        // Check if ID is already present via another URL/name
        bool idExists = false;
        List<Future<VKGroupInfo?>> checkFutures = [];
        for (var existingUrl in groupUrls) {
          checkFutures
              .add(_apiProvider.getGroupInfoByScreenName(vkToken, existingUrl));
        }
        if (checkFutures.isNotEmpty) {
          final existingInfos = await Future.wait(checkFutures);
          idExists = existingInfos
              .whereType<VKGroupInfo>()
              .any((g) => g.id == groupInfo.id);
        }

        if (idExists) {
          Get.snackbar(
            'Информация',
            'Группа "${groupInfo.name}" (ID: ${groupInfo.id}) уже есть в списке (возможно, под другим адресом).',
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
    required bool skipClosedProfiles, // Direct value from UI
    required bool skipRelationFilter, // Direct value from UI
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

    // Check if filters actually changed before triggering reload signal
    final bool filtersChanged = _vkToken.value != vkToken ||
        !listEquals(cities, currentCities) ||
        ageFrom.value != parsedAgeFrom ||
        ageTo.value != parsedAgeTo ||
        this.sexFilter.value != sexFilter ||
        !listEquals(groupUrls, currentGroupUrls) ||
        this.skipClosedProfiles.value != skipClosedProfiles ||
        this.skipRelationFilter.value != skipRelationFilter; // Check new filter

    // Update internal reactive variables BEFORE saving
    _vkToken.value = vkToken;
    _defaultMessage.value = defaultMessage;
    _theme.value = theme;

    // Use assignAll or clear/addAll for lists to ensure reactivity
    cities.assignAll(currentCities);
    groupUrls.assignAll(currentGroupUrls);

    ageFrom.value = parsedAgeFrom;
    ageTo.value = parsedAgeTo;
    this.sexFilter.value = sexFilter;
    this.skipClosedProfiles.value = skipClosedProfiles;
    this.skipRelationFilter.value = skipRelationFilter; // Update reactive variable

    // Save to repository using the updated internal values
    try {
      await _settingsRepository.saveSettings(
        vkToken: _vkToken.value,
        defaultMessage: _defaultMessage.value,
        theme: _theme.value,
        cities: this.cities.toList(), // Pass current list
        ageFrom: this.ageFrom.value, // Pass current value
        ageTo: this.ageTo.value,     // Pass current value
        sexFilter: this.sexFilter.value, // Pass current value
        groupUrls: this.groupUrls.toList(), // Pass current list
        skipClosedProfiles: this.skipClosedProfiles.value, // Pass current value
        skipRelationFilter: this.skipRelationFilter.value, // Pass current value
      );

      // Update theme immediately
      _themeService.updateTheme(theme);

      // Trigger reload only if relevant filters changed
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
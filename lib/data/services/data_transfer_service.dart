// --- File: lib/data/services/data_transfer_service.dart ---
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vktinder/data/models/statistics.dart';
import 'package:vktinder/data/models/vk_city_info.dart';
import 'package:vktinder/data/models/vk_group_info.dart';
import 'package:vktinder/data/repositories/settings_repository_impl.dart';
import 'package:vktinder/data/repositories/statistics_repository.dart';

/// Service for exporting and importing app data between devices
class DataTransferService extends GetxService {
  final SettingsRepository _settingsRepository = Get.find<SettingsRepository>();
  final StatisticsRepository _statisticsRepository = Get.find<StatisticsRepository>();

  /// Export all app data to a file
  Future<void> exportData() async {
    try {
      // 1. Collect all app data
      final appData = await _collectAppData();

      // 2. Serialize to JSON
      final jsonData = jsonEncode(appData);

      // Convert JSON string to bytes
      final bytes = utf8.encode(jsonData);

      // 3. Save to file with bytes parameter (required for Android & iOS)
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Save VK Tinder Data',
        fileName: 'vktinder_data_${DateTime.now().millisecondsSinceEpoch}.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: bytes,
      );

      if (result != null) {
        Get.snackbar(
          'Успех',
          'Данные успешно экспортированы',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green[100],
          colorText: Colors.green[900],
          margin: const EdgeInsets.all(8),
          borderRadius: 10,
          duration: const Duration(seconds: 2),
          icon: const Icon(Icons.check_circle, color: Colors.green),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Ошибка экспорта',
        'Не удалось экспортировать данные: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
        margin: const EdgeInsets.all(8),
        borderRadius: 10,
        duration: const Duration(seconds: 4),
      );
    }
  }

  /// Import app data from a file
  Future<void> importData() async {
    FilePickerResult? result;

    try {
      // 1. Pick file with simplified options to avoid EventChannel issues
      try {
        result = await FilePicker.platform.pickFiles(
          // Simplified options to avoid EventChannel issues
          withData: true, // Get file data directly to avoid path issues
        );
      } catch (e) {
        print('Error picking file: $e');
        throw Exception('Не удалось выбрать файл: $e');
      }

      if (result != null) {
        if (result.files.single.bytes != null) {
          // Use bytes directly if available
          final jsonData = utf8.decode(result.files.single.bytes!);

          // 2. Parse JSON
          final appData = jsonDecode(jsonData) as Map<String, dynamic>;

          // 3. Restore data
          await _restoreAppData(appData);

          Get.snackbar(
            'Успех',
            'Данные успешно импортированы',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green[100],
            colorText: Colors.green[900],
            margin: const EdgeInsets.all(8),
            borderRadius: 10,
            duration: const Duration(seconds: 2),
            icon: const Icon(Icons.check_circle, color: Colors.green),
          );
        } else if (result.files.single.path != null) {
          // Fallback to path if bytes not available
          final file = File(result.files.single.path!);
          final jsonData = await file.readAsString();

          // 2. Parse JSON
          final appData = jsonDecode(jsonData) as Map<String, dynamic>;

          // 3. Restore data
          await _restoreAppData(appData);

          Get.snackbar(
            'Успех',
            'Данные успешно импортированы',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green[100],
            colorText: Colors.green[900],
            margin: const EdgeInsets.all(8),
            borderRadius: 10,
            duration: const Duration(seconds: 2),
            icon: const Icon(Icons.check_circle, color: Colors.green),
          );
        } else {
          throw Exception('Не удалось получить данные файла');
        }
      }
    } catch (e) {
      print('Error importing data: $e');
      Get.snackbar(
        'Ошибка импорта',
        'Не удалось импортировать данные: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
        margin: const EdgeInsets.all(8),
        borderRadius: 10,
        duration: const Duration(seconds: 4),
      );
    }
  }

  /// Collect all app data for export
  Future<Map<String, dynamic>> _collectAppData() async {
    // 1. Collect settings
    final vkToken = _settingsRepository.getVkToken();
    final defaultMessage = _settingsRepository.getDefaultMessage();
    final theme = _settingsRepository.getTheme();
    final cities = _settingsRepository.getCities();
    final (ageFrom, ageTo) = _settingsRepository.getAgeRange();
    final sexFilter = _settingsRepository.getSexFilter();
    final groupUrls = _settingsRepository.getGroupUrls();
    final groupInfos = _settingsRepository.getGroupInfos();
    final cityInfos = _settingsRepository.getCityInfos();
    final skipClosedProfiles = _settingsRepository.getSkipClosedProfiles();
    final skipRelationFilter = _settingsRepository.getSkipRelationFilter();

    // 2. Collect statistics
    final userActions = await _statisticsRepository.loadUserActions();
    final skippedUserIds = await _statisticsRepository.loadSkippedUserIds();

    // 3. Create data structure
    return {
      'settings': {
        'vkToken': vkToken,
        'defaultMessage': defaultMessage,
        'theme': theme,
        'cities': cities,
        'ageFrom': ageFrom,
        'ageTo': ageTo,
        'sexFilter': sexFilter,
        'groupUrls': groupUrls,
        'groupInfos': groupInfos.map((info) => info.toJson()).toList(),
        'cityInfos': cityInfos.map((info) => info.toJson()).toList(),
        'skipClosedProfiles': skipClosedProfiles,
        'skipRelationFilter': skipRelationFilter,
      },
      'statistics': {
        'userActions': _serializeUserActions(userActions),
        'skippedUserIds': skippedUserIds.toList(),
      }
    };
  }

  /// Restore app data from import
  Future<void> _restoreAppData(Map<String, dynamic> appData) async {
    // 1. Extract settings
    final settings = appData['settings'] as Map<String, dynamic>;
    final vkToken = settings['vkToken'] as String;
    final defaultMessage = settings['defaultMessage'] as String;
    final theme = settings['theme'] as String;
    final cities = (settings['cities'] as List).cast<String>();
    final ageFrom = settings['ageFrom'] as int?;
    final ageTo = settings['ageTo'] as int?;
    final sexFilter = settings['sexFilter'] as int;
    final groupUrls = (settings['groupUrls'] as List).cast<String>();
    final groupInfosJson = (settings['groupInfos'] as List).cast<Map<String, dynamic>>();
    final cityInfosJson = (settings['cityInfos'] as List).cast<Map<String, dynamic>>();
    final skipClosedProfiles = settings['skipClosedProfiles'] as bool;
    final skipRelationFilter = settings['skipRelationFilter'] as bool;

    // 2. Extract statistics
    final statistics = appData['statistics'] as Map<String, dynamic>;
    final userActionsJson = statistics['userActions'] as Map<String, dynamic>;
    final skippedUserIdsJson = (statistics['skippedUserIds'] as List).cast<String>();

    // 3. Save settings
    await _settingsRepository.saveSettings(
      vkToken: vkToken,
      defaultMessage: defaultMessage,
      theme: theme,
      cities: cities,
      ageFrom: ageFrom,
      ageTo: ageTo,
      sexFilter: sexFilter,
      groupUrls: groupUrls,
      groupInfos: groupInfosJson.map((json) => VKGroupInfo.fromJson(json)).toList(),
      cityInfos: cityInfosJson.map((json) => VKCityInfo.fromJson(json)).toList(),
      skipClosedProfiles: skipClosedProfiles,
      skipRelationFilter: skipRelationFilter,
    );

    // 4. Save statistics
    final userActions = _deserializeUserActions(userActionsJson);
    await _statisticsRepository.saveUserActions(userActions);
    await _statisticsRepository.saveSkippedUserIds(skippedUserIdsJson.toSet());
  }

  /// Helper method to serialize user actions for export
  Map<String, dynamic> _serializeUserActions(Map<String, List<StatisticsUserAction>> userActions) {
    final result = <String, dynamic>{};
    userActions.forEach((groupURL, actions) {
      result[groupURL] = actions.map((action) => action.toJson()).toList();
    });
    return result;
  }

  /// Helper method to deserialize user actions from import
  Map<String, List<StatisticsUserAction>> _deserializeUserActions(Map<String, dynamic> userActionsJson) {
    final result = <String, List<StatisticsUserAction>>{};
    userActionsJson.forEach((groupURL, actionsJson) {
      final actions = (actionsJson as List).map((actionJson) {
        return StatisticsUserAction.fromJson(actionJson as String);
      }).toList();
      result[groupURL] = actions;
    });
    return result;
  }
}

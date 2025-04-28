// --- File: lib/data/services/data_transfer_service.dart ---
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vktinder/data/models/statistics.dart';
import 'package:vktinder/data/models/vk_city_info.dart';
import 'package:vktinder/data/models/vk_group_info.dart';
import 'package:vktinder/data/repositories/settings_repository_impl.dart';
import 'package:vktinder/data/repositories/statistics_repository.dart';

/// Service for exporting and importing app data between devices
class DataTransferService extends GetxService {
  // Dependencies
  final SettingsRepository _settingsRepository = Get.find<SettingsRepository>();
  final StatisticsRepository _statisticsRepository =
      Get.find<StatisticsRepository>();

  // UI constants
  static const _snackbarMargin = EdgeInsets.all(8);
  static const _snackbarBorderRadius = 10.0;
  static const _successDuration = Duration(seconds: 2);
  static const _errorDuration = Duration(seconds: 4);

  /// Exports all app data to a file
  Future<void> exportData() async {
    try {
      // Collect and serialize data
      final appData = await _collectAppData();
      final jsonData = jsonEncode(appData);
      final bytes = utf8.encode(jsonData);

      // Save to file
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Save VK Tinder Data',
        fileName: 'vktinder_data_${DateTime.now().millisecondsSinceEpoch}.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: bytes,
      );

      // Show success message if file was saved
      if (result != null) {
        _showSuccessSnackbar('Данные успешно экспортированы');
      }
    } catch (e) {
      _showErrorSnackbar('Не удалось экспортировать данные: $e');
    }
  }

  /// Imports app data from a file
  Future<void> importData() async {
    try {
      // Pick file with simplified options to avoid EventChannel issues
      final result = await FilePicker.platform.pickFiles(
        withData: true, // Get file data directly to avoid path issues
      );

      if (result == null) return;

      // Process file data
      String jsonData;
      if (result.files.single.bytes != null) {
        // Use bytes directly if available
        jsonData = utf8.decode(result.files.single.bytes!);
      } else if (result.files.single.path != null) {
        // Fallback to path if bytes not available
        final file = File(result.files.single.path!);
        jsonData = await file.readAsString();
      } else {
        throw Exception('Не удалось получить данные файла');
      }

      // Parse JSON and restore data
      final appData = jsonDecode(jsonData) as Map<String, dynamic>;
      await _restoreAppData(appData);

      _showSuccessSnackbar('Данные успешно импортированы');
    } catch (e) {
      _showErrorSnackbar('Не удалось импортировать данные: $e');
    }
  }

  /// Collects all app data for export
  Future<Map<String, dynamic>> _collectAppData() async {
    // Collect settings
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

    // Collect statistics
    final userActions = await _statisticsRepository.loadUserActions();
    final skippedUserIds = await _statisticsRepository.loadSkippedUserIds();

    // Create data structure
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

  /// Restores app data from import
  Future<void> _restoreAppData(Map<String, dynamic> appData) async {
    // Extract settings
    final settings = appData['settings'] as Map<String, dynamic>;
    final vkToken = settings['vkToken'] as String;
    final defaultMessage = settings['defaultMessage'] as String;
    final theme = settings['theme'] as String;
    final cities = (settings['cities'] as List).cast<String>();
    final ageFrom = settings['ageFrom'] as int?;
    final ageTo = settings['ageTo'] as int?;
    final sexFilter = settings['sexFilter'] as int;
    final groupUrls = (settings['groupUrls'] as List).cast<String>();
    final groupInfosJson =
        (settings['groupInfos'] as List).cast<Map<String, dynamic>>();
    final cityInfosJson =
        (settings['cityInfos'] as List).cast<Map<String, dynamic>>();
    final skipClosedProfiles = settings['skipClosedProfiles'] as bool;
    final skipRelationFilter = settings['skipRelationFilter'] as bool;

    // Extract statistics
    final statistics = appData['statistics'] as Map<String, dynamic>;
    final userActionsJson = statistics['userActions'] as Map<String, dynamic>;
    final skippedUserIdsJson =
        (statistics['skippedUserIds'] as List).cast<String>();

    // Save settings
    await _settingsRepository.saveSettings(
      vkToken: vkToken,
      defaultMessage: defaultMessage,
      theme: theme,
      cities: cities,
      ageFrom: ageFrom,
      ageTo: ageTo,
      sexFilter: sexFilter,
      groupUrls: groupUrls,
      groupInfos:
          groupInfosJson.map((json) => VKGroupInfo.fromJson(json)).toList(),
      cityInfos:
          cityInfosJson.map((json) => VKCityInfo.fromJson(json)).toList(),
      skipClosedProfiles: skipClosedProfiles,
      skipRelationFilter: skipRelationFilter,
    );

    // Save statistics
    final userActions = _deserializeUserActions(userActionsJson);
    await _statisticsRepository.saveUserActions(userActions);
    await _statisticsRepository.saveSkippedUserIds(skippedUserIdsJson.toSet());
  }

  /// Serializes user actions for export
  Map<String, dynamic> _serializeUserActions(
      Map<String, List<StatisticsUserAction>> userActions) {
    final result = <String, dynamic>{};
    userActions.forEach((groupURL, actions) {
      result[groupURL] = actions.map((action) => action.toJson()).toList();
    });
    return result;
  }

  /// Deserializes user actions from import
  Map<String, List<StatisticsUserAction>> _deserializeUserActions(
      Map<String, dynamic> userActionsJson) {
    final result = <String, List<StatisticsUserAction>>{};
    userActionsJson.forEach((groupURL, actionsJson) {
      final actions = (actionsJson as List).map((actionJson) {
        return StatisticsUserAction.fromJson(actionJson as String);
      }).toList();
      result[groupURL] = actions;
    });
    return result;
  }

  /// Shows a success snackbar with the specified message
  void _showSuccessSnackbar(String message) {
    Get.snackbar(
      'Успех',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.green[100],
      colorText: Colors.green[900],
      margin: _snackbarMargin,
      borderRadius: _snackbarBorderRadius,
      duration: _successDuration,
      icon: const Icon(Icons.check_circle, color: Colors.green),
    );
  }

  /// Shows an error snackbar with the specified message
  void _showErrorSnackbar(String message) {
    Get.snackbar(
      'Ошибка',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red[100],
      colorText: Colors.red[900],
      margin: _snackbarMargin,
      borderRadius: _snackbarBorderRadius,
      duration: _errorDuration,
    );
  }
}

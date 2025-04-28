// lib/data/repositories/statistics_repository.dart
import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:vktinder/data/models/statistics.dart';
import 'package:vktinder/data/providers/hive_storage_provider.dart';

class StatisticsRepository {
  late final HiveStorageProvider _hiveProvider;

  StatisticsRepository() {
    _hiveProvider = Get.find<HiveStorageProvider>();
  }

  // --- Load User Actions ---
  Future<Map<String, List<StatisticsUserAction>>> loadUserActions() async {
    try {
      final Map<String, List<Map<String, dynamic>>> allUserActions = await _hiveProvider.loadAllUserActions();
      final Map<String, List<StatisticsUserAction>> result = {};

      allUserActions.forEach((groupURL, actionMaps) {
        final actions = actionMaps
            .map((actionMap) {
              try {
                return StatisticsUserAction.fromMap(actionMap);
              } catch (e) {
                print('Error converting action map to StatisticsUserAction for group $groupURL: $e');
                return null;
              }
            })
            .whereType<StatisticsUserAction>() // Filter out nulls
            .toList();

        if (actions.isNotEmpty) {
          result[groupURL] = actions;
        }
      });

      print("StatisticsRepository: Loaded ${result.length} groups with actions from Hive.");
      return result;
    } catch (e) {
      print("Error loading user actions from Hive: $e");
      return {};
    }
  }

  // --- Save User Actions ---
  Future<void> saveUserActions(Map<String, List<StatisticsUserAction>> actionsMap) async {
    try {
      // Save each group's actions separately
      for (final entry in actionsMap.entries) {
        await _hiveProvider.saveUserActions(entry.key, entry.value);
      }
      print("StatisticsRepository: Saved user actions for ${actionsMap.length} groups to Hive.");
    } catch (e) {
      print("Error saving user actions to Hive: $e");
      // Consider adding more robust error handling (e.g., retry, logging)
    }
  }

  // --- Load Skipped User IDs ---
  Future<Set<String>> loadSkippedUserIds() async {
    try {
      final skippedIds = await _hiveProvider.loadSkippedUserIds();
      print("StatisticsRepository: Loaded ${skippedIds.length} skipped user IDs from Hive.");
      return skippedIds;
    } catch (e) {
      print("Error loading skipped user IDs from Hive: $e");
      return {};
    }
  }

  // --- Save Skipped User IDs ---
  Future<void> saveSkippedUserIds(Set<String> skippedIds) async {
    try {
      await _hiveProvider.saveSkippedUserIds(skippedIds);
      print("StatisticsRepository: Saved ${skippedIds.length} skipped user IDs to Hive.");
    } catch (e) {
      print("Error saving skipped user IDs to Hive: $e");
      // Consider adding more robust error handling
      if (e is OutOfMemoryError) {
        print("FATAL: OutOfMemoryError while saving skipped IDs to Hive. Data might be lost.");
        // Potentially try to save a smaller subset or log the error externally
      }
    }
  }
}

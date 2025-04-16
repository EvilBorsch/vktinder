// lib/data/repositories/statistics_repository.dart
import 'dart:async';
import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:vktinder/data/models/statistics.dart';

class StatisticsRepository {
  final _storage = GetStorage();

  final _groupUserKey = "statistics_user_actions_v2"; // Renamed key for updated format
  final _skippedUsersKey = "statistics_skipped_ids_v2"; // Renamed key

  // --- Load User Actions ---
  Future<Map<String, List<StatisticsUserAction>>> loadUserActions() async {
    final rawValue = _storage.read<String>(_groupUserKey);
    if (rawValue == null || rawValue.isEmpty) {
      return {}; // Return empty map if no data
    }

    try {
      final Map<String, dynamic> decodedMap = jsonDecode(rawValue);
      final Map<String, List<StatisticsUserAction>> dbGroupUsers = {};

      decodedMap.forEach((groupURL, rawActionsList) {
        if (rawActionsList is List) {
          final actions = rawActionsList
              .map((rawAction) {
            try {
              // IMPORTANT: jsonDecode *each action* because they were stored as strings
              return StatisticsUserAction.fromJson(rawAction as String);
            } catch (e) {
              print('Error decoding individual user action for group $groupURL: $e');
              return null; // Skip corrupted entries
            }
          })
              .whereType<StatisticsUserAction>() // Filter out nulls
              .toList();
          if (actions.isNotEmpty) {
            dbGroupUsers[groupURL] = actions;
          }
        }
      });
      print("StatisticsRepository: Loaded ${dbGroupUsers.length} groups with actions.");
      return dbGroupUsers;
    } catch (e) {
      print("Error decoding user actions map: $e");
      await _storage.remove(_groupUserKey); // Clear corrupted data
      return {};
    }
  }

  // --- Save User Actions ---
  Future<void> saveUserActions(Map<String, List<StatisticsUserAction>> actionsMap) async {
    try {
      // IMPORTANT: Encode *each action* to JSON string before encoding the map
      final Map<String, List<String>> encodableMap = actionsMap.map(
            (groupURL, actions) => MapEntry(
            groupURL, actions.map((action) => action.toJson()).toList()),
      );
      final String encodedData = jsonEncode(encodableMap);
      await _storage.write(_groupUserKey, encodedData);
      print("StatisticsRepository: Saved user actions for ${actionsMap.length} groups.");
    } catch (e) {
      print("Error encoding/saving user actions map: $e");
      // Consider adding more robust error handling (e.g., retry, logging)
    }
  }

  // --- Load Skipped User IDs ---
  Future<Set<String>> loadSkippedUserIds() async {
    final rawValue = _storage.read<String>(_skippedUsersKey);
    if (rawValue == null || rawValue.isEmpty) {
      return {}; // Return empty set
    }
    try {
      // Decode the JSON string into a List<dynamic>
      final List<dynamic> decodedList = jsonDecode(rawValue);
      // Convert to Set<String>, ensuring elements are strings
      final Set<String> skippedIds = decodedList.map((id) => id.toString()).toSet();
      print("StatisticsRepository: Loaded ${skippedIds.length} skipped user IDs.");
      return skippedIds;
    } catch (e) {
      print("Error decoding skipped user IDs: $e");
      await _storage.remove(_skippedUsersKey); // Clear corrupted data
      return {};
    }
  }

  // --- Save Skipped User IDs ---
  Future<void> saveSkippedUserIds(Set<String> skippedIds) async {
    try {
      // Convert Set to List for JSON encoding
      final List<String> idList = skippedIds.toList();
      final String encodedData = jsonEncode(idList);
      await _storage.write(_skippedUsersKey, encodedData);
      print("StatisticsRepository: Saved ${skippedIds.length} skipped user IDs.");
    } catch (e) {
      print("Error encoding/saving skipped user IDs: $e");
      // Consider adding more robust error handling
      // Avoid re-throwing the OutOfMemoryError here if possible
      if (e is OutOfMemoryError) {
        print("FATAL: OutOfMemoryError while saving skipped IDs. Data might be lost.");
        // Potentially try to save a smaller subset or log the error externally
      }
    }
  }
}

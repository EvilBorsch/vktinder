import 'package:hive_flutter/hive_flutter.dart';
import 'package:vktinder/data/models/hive/vk_group_user.dart';
import 'package:vktinder/data/models/hive/skipped_user_ids.dart';
import 'package:vktinder/data/models/hive/hive_adapters.dart';
import 'package:vktinder/data/models/statistics.dart';
import 'package:vktinder/data/models/vk_group_user.dart' as original;
import 'package:get/get.dart';
import 'dart:convert';

class HiveStorageProvider extends GetxService {
  static const String userActionsBoxName = 'user_actions';
  static const String skippedUserIdsBoxName = 'skipped_user_ids';
  static const String persistedCardsBoxName = 'persisted_cards';

  // Initialize Hive
  static Future<void> init() async {
    await Hive.initFlutter();

    // Register adapters
    HiveAdapters.registerAdapters();

    // Open boxes
    await Hive.openBox<String>(userActionsBoxName); // Store JSON strings instead of objects
    await Hive.openBox<HiveSkippedUserIds>(skippedUserIdsBoxName);
    await Hive.openBox<HiveVKGroupUser>(persistedCardsBoxName);
  }

  // Initialize as a GetX service
  static Future<HiveStorageProvider> initService() async {
    await init();
    final provider = HiveStorageProvider();
    return Get.put(provider);
  }

  // --- User Actions Methods ---

  // Save user actions for a group
  Future<void> saveUserActions(String groupURL, List<StatisticsUserAction> actions) async {
    final box = Hive.box<String>(userActionsBoxName);

    // Convert actions to maps and then to JSON string
    final actionMaps = actions.map((action) => action.toMap()).toList();
    final jsonString = jsonEncode(actionMaps);

    // Save to box with group URL as key
    await box.put(groupURL, jsonString);
  }

  // Load user actions for a group
  Future<List<Map<String, dynamic>>> loadUserActions(String groupURL) async {
    final box = Hive.box<String>(userActionsBoxName);

    // Get JSON string from box
    final jsonString = box.get(groupURL);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      // Decode JSON string to list of maps
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      print("Error decoding user actions for group $groupURL: $e");
      return [];
    }
  }

  // Load all user actions
  Future<Map<String, List<Map<String, dynamic>>>> loadAllUserActions() async {
    final box = Hive.box<String>(userActionsBoxName);
    final result = <String, List<Map<String, dynamic>>>{};

    // Iterate through all keys (group URLs)
    for (final groupURL in box.keys) {
      if (groupURL is String) {
        final jsonString = box.get(groupURL);
        if (jsonString != null && jsonString.isNotEmpty) {
          try {
            // Decode JSON string to list of maps
            final List<dynamic> decoded = jsonDecode(jsonString);
            result[groupURL] = decoded.cast<Map<String, dynamic>>();
          } catch (e) {
            print("Error decoding user actions for group $groupURL: $e");
            // Skip this group if there's an error
          }
        }
      }
    }

    return result;
  }

  // --- Skipped User IDs Methods ---

  // Save skipped user IDs
  Future<void> saveSkippedUserIds(Set<String> userIds) async {
    final box = Hive.box<HiveSkippedUserIds>(skippedUserIdsBoxName);

    // Create a HiveSkippedUserIds object
    final hiveSkippedUserIds = HiveSkippedUserIds.fromSet(userIds);

    // Clear existing IDs and save the new ones
    await box.clear();
    await box.add(hiveSkippedUserIds);
  }

  // Load skipped user IDs
  Future<Set<String>> loadSkippedUserIds() async {
    final box = Hive.box<HiveSkippedUserIds>(skippedUserIdsBoxName);

    // Get the HiveSkippedUserIds object
    final hiveSkippedUserIds = box.values.isNotEmpty ? box.values.first : null;

    // Convert to a Set<String>
    return hiveSkippedUserIds?.toSet() ?? <String>{};
  }

  // --- Persisted Cards Methods ---

  // Save persisted cards
  Future<void> savePersistedCards(List<original.VKGroupUser> users) async {
    final box = Hive.box<HiveVKGroupUser>(persistedCardsBoxName);

    // Clear existing cards
    await box.clear();

    // Convert users to Hive models and add to box
    for (final user in users) {
      await box.add(HiveVKGroupUser.fromVKGroupUser(user));
    }
  }

  // Load persisted cards
  Future<List<Map<String, dynamic>>> loadPersistedCards() async {
    final box = Hive.box<HiveVKGroupUser>(persistedCardsBoxName);

    // Convert Hive models to maps for creating VKGroupUser objects
    return box.values.map((user) => user.toVKGroupUserMap()).toList();
  }

  // Clear persisted cards
  Future<void> clearPersistedCards() async {
    final box = Hive.box<HiveVKGroupUser>(persistedCardsBoxName);
    await box.clear();
  }
}

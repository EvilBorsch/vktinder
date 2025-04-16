// --- File: lib/presentation/controllers/statistics_controller.dart ---
// lib/presentation/controllers/statistics_controller.dart
import 'package:get/get.dart';
import 'package:vktinder/data/models/statistics.dart';
import 'package:vktinder/data/models/vk_group_user.dart'; // Need this for the input type of addUserAction
import 'package:vktinder/data/repositories/statistics_repository.dart';
import 'dart:async'; // For Timer

class StatisticsController extends GetxController {
  final StatisticsRepository _statisticsRepository = Get.find<StatisticsRepository>();

  // In-memory state for user actions (Map<GroupURL, RxList<Action>>)
  final RxMap<String, RxList<StatisticsUserAction>> userActions =
      <String, RxList<StatisticsUserAction>>{}.obs;

  // In-memory state for skipped users (Set for efficient checking)
  final RxSet<String> skippedUserIDs = <String>{}.obs;

  // Loading state for initial load
  final RxBool isLoading = true.obs;

  // Debouncer for saving data
  Timer? _saveDebounceTimer;
  final Duration _saveDebounceDuration = const Duration(seconds: 1); // Save 2 seconds after last action


  @override
  void onInit() {
    super.onInit();
    _loadInitialData();
  }

  @override
  void onClose() {
    _saveDebounceTimer?.cancel(); // Cancel timer if controller is destroyed
    // Consider a final save on close if needed, but debouncing should cover most cases
    // _saveDataImmediate();
    super.onClose();
  }


  // --- Public methods ---

  /// Adds a user action (like/dislike) to the statistics.
  Future<void> addUserAction(String groupURL, VKGroupUser user, String actionType) async {
    final action = StatisticsUserAction(
      userId: user.userID,
      name: user.name,
      surname: user.surname,
      avatar: user.avatar,
      groupURL: groupURL, // Use the provided groupURL
      action: actionType,
      actionDate: DateTime.now(),
    );

    // 1. Update in-memory map
    if (!userActions.containsKey(groupURL)) {
      // Ensure reactivity by assigning a new RxList if the key is new
      userActions[groupURL] = <StatisticsUserAction>[].obs;
    }
    // Add to the beginning for chronological display (newest first)
    // Use insert(0, action) on the existing RxList to trigger updates
    userActions[groupURL]!.insert(0, action);
    // userActions.refresh(); // May not be needed if directly modifying RxList content

    // 2. Update in-memory set of skipped IDs (all swiped users are skipped)
    skippedUserIDs.add(user.userID);
    // skippedUserIDs.refresh(); // May not be needed

    // 3. Debounce save operations
    _debounceSaveData();
  }

  /// Refreshes the statistics data from storage only if needed (e.g., if controller wasn't permanent).
  /// Mostly forces UI refresh now as data is kept in sync.
  Future<void> refreshStatisticsView() async {
    print("StatisticsController: Refreshing view (forcing UI update)");
    userActions.refresh();
    skippedUserIDs.refresh();
  }

  // --- Internal Methods ---

  /// Loads user actions from the repository.
  Future<void> _loadUserActionsFromRepo() async {
    final loadedActionsMap = await _statisticsRepository.loadUserActions();
    final observableMap = <String, RxList<StatisticsUserAction>>{};
    loadedActionsMap.forEach((key, value) {
      // Sort actions by date descending when loading for consistency
      value.sort((a, b) => b.actionDate.compareTo(a.actionDate));
      observableMap[key] = value.obs;
    });
    userActions.value = observableMap; // Assign the new map to the RxMap
    print("StatisticsController: Loaded ${userActions.length} groups with actions into memory.");
  }

  /// Loads skipped user IDs from the repository.
  Future<void> _loadSkippedUserIdsFromRepo() async {
    final loadedIds = await _statisticsRepository.loadSkippedUserIds();
    skippedUserIDs.value = loadedIds; // Assign the loaded set to the RxSet
    print("StatisticsController: Loaded ${skippedUserIDs.length} skipped IDs into memory.");
  }

  /// Loads all data initially.
  Future<void> _loadInitialData() async {
    isLoading.value = true;
    // Clear existing in-memory data before loading
    userActions.clear();
    skippedUserIDs.clear();
    try {
      await Future.wait([
        _loadUserActionsFromRepo(),
        _loadSkippedUserIdsFromRepo(),
      ]);
    } catch (e) {
      print("Error loading initial statistics data: $e");
      Get.snackbar('Ошибка', 'Не удалось загрузить статистику: $e',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  /// Debounces the save operation.
  void _debounceSaveData() {
    if (_saveDebounceTimer?.isActive ?? false) _saveDebounceTimer!.cancel();
    _saveDebounceTimer = Timer(_saveDebounceDuration, () {
      _saveDataImmediate();
    });
  }


  /// Saves the current in-memory state to storage immediately.
  Future<void> _saveDataImmediate() async {
    // Convert Map<String, RxList<StatisticsUserAction>> to Map<String, List<StatisticsUserAction>>
    final Map<String, List<StatisticsUserAction>> plainActionsMap = {};
    userActions.forEach((key, rxList) {
      plainActionsMap[key] = rxList.toList(); // Convert RxList to List
    });

    // Create a copy of the set for saving
    final Set<String> idsToSave = skippedUserIDs.value.toSet();

    print("StatisticsController: Saving data: ${plainActionsMap.length} action groups, ${idsToSave.length} skipped IDs.");

    // Save both datasets concurrently
    try {
      await Future.wait([
        _statisticsRepository.saveUserActions(plainActionsMap),
        _statisticsRepository.saveSkippedUserIds(idsToSave),
      ]);
      print("StatisticsController: Saved current state successfully.");
    } catch (e) {
      print("Error saving statistics data: $e");
      // Handle saving error (e.g., show persistent error message)
      Get.snackbar('Ошибка Сохранения', 'Не удалось сохранить прогресс: $e', snackPosition: SnackPosition.BOTTOM);
    }
  }


  // --- Getter for HomeController ---
  /// Provides the set of skipped user IDs for filtering in HomeController.
  Set<String> get skippedIdsSet => skippedUserIDs.value.toSet(); // Return a copy to prevent modification outside controller
}
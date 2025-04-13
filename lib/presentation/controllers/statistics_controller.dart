// lib/presentation/controllers/statistics_controller.dart
import 'package:get/get.dart';
import 'package:vktinder/data/models/statistics.dart';
import 'package:vktinder/data/models/vk_group_user.dart'; // Need this for the input type of addUserAction
import 'package:vktinder/data/repositories/statistics_repository.dart';

class StatisticsController extends GetxController {
  final StatisticsRepository _statisticsRepository = Get.find<StatisticsRepository>();

  // In-memory state for user actions (Map<GroupURL, ListOfActions>)
  final RxMap<String, RxList<StatisticsUserAction>> userActions =
      <String, RxList<StatisticsUserAction>>{}.obs;

  // In-memory state for skipped users (Set for efficient checking)
  final RxSet<String> skippedUserIDs = <String>{}.obs;

  // Loading state for initial load
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    _loadInitialData();
  }

  // --- Public methods (Interface remains similar) ---

  /// Adds a user action (like/dislike) to the statistics.
  /// IMPORTANT: Now takes the original VKGroupUser only to extract necessary data.
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
      userActions[groupURL] = <StatisticsUserAction>[].obs;
    }
    // Add to the beginning for chronological display (newest first)
    userActions[groupURL]!.insert(0, action);

    // 2. Update in-memory set of skipped IDs (all swiped users are skipped)
    skippedUserIDs.add(user.userID);

    // 3. Trigger save operations (can be awaited but might not be necessary for UI responsiveness)
    // Convert RxMap/RxList to plain Map/List for saving
    _saveData();
  }

  /// Refreshes the statistics data from storage.
  /// Called by the StatisticsPage when it becomes visible.
  Future<void> refreshStatisticsView() async {
    // No need to reload from storage here if the controller is permanent
    // and data is kept in sync. If the controller wasn't permanent,
    // we would reload here.
    print("StatisticsController: Refreshing view (data is in memory)");
    // Force UI update if needed (though Rx should handle it)
    userActions.refresh();
    skippedUserIDs.refresh();
  }

  /// Loads user actions from the repository (typically called during init).
  /// Renamed from getUserActions to avoid confusion with simple getter.
  Future<void> _loadUserActionsFromRepo() async {
    final loadedActionsMap = await _statisticsRepository.loadUserActions();
    // Convert the loaded Map<String, List> to Map<String, RxList>
    final observableMap = <String, RxList<StatisticsUserAction>>{};
    loadedActionsMap.forEach((key, value) {
      observableMap[key] = value.obs;
    });
    userActions.value = observableMap; // Assign the new map to the RxMap
    print("StatisticsController: Loaded user actions into memory.");
  }

  /// Loads skipped user IDs from the repository (typically called during init).
  /// Renamed from getSkippedIDs.
  Future<void> _loadSkippedUserIdsFromRepo() async {
    final loadedIds = await _statisticsRepository.loadSkippedUserIds();
    skippedUserIDs.value = loadedIds; // Assign the loaded set to the RxSet
    print("StatisticsController: Loaded skipped IDs into memory.");
  }

  /// Loads all data initially.
  Future<void> _loadInitialData() async {
    isLoading.value = true;
    try {
      await Future.wait([
        _loadUserActionsFromRepo(),
        _loadSkippedUserIdsFromRepo(),
      ]);
    } catch (e) {
      print("Error loading initial statistics data: $e");
      // Handle error appropriately, maybe show a snackbar
      Get.snackbar('Ошибка', 'Не удалось загрузить статистику: $e',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  /// Saves the current in-memory state to storage.
  /// This can be called after each action or debounced/throttled later.
  Future<void> _saveData() async {
    // Convert Map<String, RxList<StatisticsUserAction>> to Map<String, List<StatisticsUserAction>>
    final Map<String, List<StatisticsUserAction>> plainActionsMap = {};
    userActions.forEach((key, rxList) {
      plainActionsMap[key] = rxList.toList(); // Convert RxList to List
    });

    // Save both datasets
    try {
      await Future.wait([
        _statisticsRepository.saveUserActions(plainActionsMap),
        _statisticsRepository.saveSkippedUserIds(skippedUserIDs.value.toSet()), // Ensure it's a Set
      ]);
      print("StatisticsController: Saved current state.");
    } catch (e) {
      print("Error saving statistics data: $e");
      // Handle saving error (e.g., show persistent error message)
      // Be cautious about OutOfMemoryError here too, although it's less likely now
    }
  }


  // --- Getter for HomeController ---
  /// Provides the set of skipped user IDs for filtering in HomeController.
  Set<String> get skippedIdsSet => skippedUserIDs.value.toSet(); // Return a copy or the reactive set itself

}

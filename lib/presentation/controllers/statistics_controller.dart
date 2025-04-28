// --- File: lib/presentation/controllers/statistics_controller.dart ---
import 'package:get/get.dart';
import 'package:vktinder/data/models/statistics.dart';
import 'package:vktinder/data/models/vk_group_user.dart';
import 'package:vktinder/data/repositories/statistics_repository.dart';
import 'dart:async';

/// Controller responsible for managing user action statistics and skipped user IDs
class StatisticsController extends GetxController {
  // Dependencies
  final StatisticsRepository _statisticsRepository =
      Get.find<StatisticsRepository>();

  // Observable state
  final RxMap<String, RxList<StatisticsUserAction>> userActions =
      <String, RxList<StatisticsUserAction>>{}.obs;
  final RxSet<String> skippedUserIDs = <String>{}.obs;
  final RxBool isLoading = true.obs;

  // Configuration
  final Duration _saveDebounceDuration = const Duration(seconds: 1);

  // Debounce timer
  Timer? _saveDebounceTimer;

  @override
  void onInit() {
    super.onInit();
    _loadInitialData();
  }

  @override
  void onClose() {
    _saveDebounceTimer?.cancel();
    super.onClose();
  }

  /// Adds a user action (like/dislike) to the statistics
  Future<void> addUserAction(
      String groupURL, VKGroupUser user, String actionType) async {
    final action = StatisticsUserAction(
      userId: user.userID,
      name: user.name,
      surname: user.surname,
      avatar: user.avatar,
      groupURL: groupURL,
      cityName: user.city,
      action: actionType,
      actionDate: DateTime.now(),
    );

    // Update in-memory map
    if (!userActions.containsKey(groupURL)) {
      userActions[groupURL] = <StatisticsUserAction>[].obs;
    }

    // Add to the beginning for chronological display (newest first)
    userActions[groupURL]!.insert(0, action);

    // Update in-memory set of skipped IDs
    skippedUserIDs.add(user.userID);

    // Debounce save operations
    _debounceSaveData();
  }

  /// Refreshes the statistics view by forcing UI update
  Future<void> refreshStatisticsView() async {
    userActions.refresh();
    skippedUserIDs.refresh();
  }

  /// Loads all data initially
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
      if (!isClosed) {
        _showErrorSnackbar('Не удалось загрузить статистику: $e');
      }
    } finally {
      if (!isClosed) {
        isLoading.value = false;
      }
    }
  }

  /// Loads user actions from the repository
  Future<void> _loadUserActionsFromRepo() async {
    final loadedActionsMap = await _statisticsRepository.loadUserActions();
    final observableMap = <String, RxList<StatisticsUserAction>>{};

    loadedActionsMap.forEach((key, value) {
      // Sort actions by date descending when loading for consistency
      value.sort((a, b) => b.actionDate.compareTo(a.actionDate));
      observableMap[key] = value.obs;
    });

    if (!isClosed) {
      userActions.value = observableMap;
    }
  }

  /// Loads skipped user IDs from the repository
  Future<void> _loadSkippedUserIdsFromRepo() async {
    final loadedIds = await _statisticsRepository.loadSkippedUserIds();

    if (!isClosed) {
      skippedUserIDs.value = loadedIds;
    }
  }

  /// Debounces the save operation
  void _debounceSaveData() {
    if (_saveDebounceTimer?.isActive ?? false) {
      _saveDebounceTimer!.cancel();
    }

    _saveDebounceTimer = Timer(_saveDebounceDuration, () {
      _saveDataImmediate();
    });
  }

  /// Saves the current in-memory state to storage immediately
  Future<void> _saveDataImmediate() async {
    if (isClosed) return;

    // Convert RxMap to plain Map for saving
    final Map<String, List<StatisticsUserAction>> plainActionsMap = {};
    userActions.forEach((key, rxList) {
      plainActionsMap[key] = rxList.toList();
    });

    // Create a copy of the set for saving
    final Set<String> idsToSave = skippedUserIDs.value.toSet();

    // Save both datasets concurrently
    try {
      await Future.wait([
        _statisticsRepository.saveUserActions(plainActionsMap),
        _statisticsRepository.saveSkippedUserIds(idsToSave),
      ]);
    } catch (e) {
      if (!isClosed) {
        _showErrorSnackbar('Не удалось сохранить прогресс: $e');
      }
    }
  }

  /// Shows an error snackbar with the specified message
  void _showErrorSnackbar(String message) {
    Get.snackbar(
      'Ошибка',
      message,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 4),
    );
  }

  /// Provides the set of skipped user IDs for filtering
  Set<String> get skippedIdsSet => skippedUserIDs.value.toSet();
}

// --- File: lib/presentation/controllers/home_controller.dart ---
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vktinder/data/models/statistics.dart';
import 'package:vktinder/data/models/vk_group_user.dart';
import 'package:vktinder/presentation/controllers/settings_controller.dart';
import 'package:vktinder/data/repositories/group_users_repository_impl.dart';
import 'package:vktinder/presentation/controllers/statistics_controller.dart';
import 'package:vktinder/data/providers/local_storage_provider.dart';
import 'dart:async';

/// Controller responsible for managing the home screen with user cards
class HomeController extends GetxController {
  // Dependencies
  final SettingsController _settingsController = Get.find<SettingsController>();
  final GroupUsersRepository _groupUsersRepository =
      Get.find<GroupUsersRepository>();
  final StatisticsController _statisticsController =
      Get.find<StatisticsController>();
  final LocalStorageProvider _localStorageProvider =
      Get.find<LocalStorageProvider>();

  // Observable state
  final RxList<VKGroupUser> users = <VKGroupUser>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool isSendingMessage = false.obs;
  final RxnString errorMessage = RxnString();

  // Configuration
  final int _loadMoreThreshold = 5;
  final Duration _saveStackDebounceDuration = const Duration(milliseconds: 600);
  final Duration _fetchDebounceDuration = const Duration(milliseconds: 500);

  // Debounce timers
  Timer? _saveStackDebounceTimer;
  Timer? _fetchDebounceTimer;

  // Getters for settings
  String get vkToken => _settingsController.vkToken;

  String get defaultMessage => _settingsController.defaultMessage;

  bool get hasVkToken => vkToken.isNotEmpty;

  bool get hasGroupsConfigured => _settingsController.groupUrls.isNotEmpty;

  // Internal state
  bool _justLoadedFromDisk = false;
  bool _isApiFetchInProgress = false;

  @override
  void onInit() {
    super.onInit();

    // Listen for settings changes and reload data when they change
    debounce<int>(
      _settingsController.settingsChanged,
      (_) {
        // Cancel any pending operations
        _fetchDebounceTimer?.cancel();
        _saveStackDebounceTimer?.cancel();

        // Clear existing data and reload
        _clearPersistedAndMemoryStack();
        _triggerApiFetch(isInitialLoad: true);
      },
      time: const Duration(milliseconds: 500),
    );

    // Initialize card stack after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCardStack();
    });
  }

  @override
  void onClose() {
    // Cancel all timers to prevent memory leaks
    _saveStackDebounceTimer?.cancel();
    _fetchDebounceTimer?.cancel();
    super.onClose();
  }

  /// Initializes the card stack by loading persisted cards or fetching from API
  Future<void> _initializeCardStack() async {
    // Reset state
    isLoading.value = true;
    errorMessage.value = null;
    users.clear();
    _isApiFetchInProgress = false;

    // Check prerequisites
    if (!hasVkToken) {
      errorMessage.value = "Необходимо указать VK токен в настройках.";
      isLoading.value = false;
      return;
    }

    if (!hasGroupsConfigured) {
      errorMessage.value =
          "Необходимо добавить хотя бы одну группу в настройках.";
      isLoading.value = false;
      return;
    }

    // Try to load persisted cards
    List<VKGroupUser> persistedUsers = [];
    try {
      persistedUsers = await _localStorageProvider.loadPersistedCards();
    } catch (e) {
      // If loading fails, clear persisted cards to prevent future errors
      await _localStorageProvider.clearPersistedCards();
    }

    // If we have persisted users, use them and fetch more if needed
    if (persistedUsers.isNotEmpty) {
      users.assignAll(persistedUsers);
      _justLoadedFromDisk = true;
      isLoading.value = false;
      _checkAndFetchMoreIfNeeded(delay: const Duration(milliseconds: 100));
    } else {
      // Otherwise, fetch from API
      await _triggerApiFetch(isInitialLoad: true);
    }

    // Ensure loading state is consistent
    if (isLoading.value && persistedUsers.isNotEmpty) {
      isLoading.value = false;
    }
  }

  /// Loads cards from API with option to force reload
  Future<void> loadCardsFromAPI({required bool forceReload}) async {
    if (!forceReload) {
      return; // Only proceed if force reload is requested
    }

    // Cancel any pending operations
    _fetchDebounceTimer?.cancel();
    _saveStackDebounceTimer?.cancel();

    // Clear existing data and reload
    await _clearPersistedAndMemoryStack();
    await _triggerApiFetch(isInitialLoad: true);
  }

  /// Triggers an API fetch operation to load users
  Future<void> _triggerApiFetch({required bool isInitialLoad}) async {
    // Skip if another fetch is already in progress
    if (_isApiFetchInProgress) {
      return;
    }

    // Check prerequisites
    if (!hasVkToken || !hasGroupsConfigured) {
      _handleMissingPrerequisites();
      return;
    }

    _isApiFetchInProgress = true;
    _updateLoadingState(isInitialLoad);

    try {
      final fetchedUsers = await _fetchUsersFromRepository();

      if (isClosed) return; // Skip processing if controller is disposed

      _processNewUsers(fetchedUsers, isInitialLoad);
    } catch (e) {
      if (isClosed) return; // Skip error handling if controller is disposed

      _handleFetchError(e, isInitialLoad);
    } finally {
      if (!isClosed) {
        // Reset flags only if controller is still active
        _isApiFetchInProgress = false;
        isLoading.value = false;
        isLoadingMore.value = false;
      }
    }
  }

  /// Updates loading state based on whether this is an initial or background load
  void _updateLoadingState(bool isInitialLoad) {
    if (isInitialLoad) {
      if (!isLoading.value) isLoading.value = true;
      if (isLoadingMore.value) isLoadingMore.value = false;
      errorMessage.value = null;
    } else {
      if (!isLoadingMore.value) isLoadingMore.value = true;
      if (isLoading.value) isLoading.value = false;
    }
  }

  /// Handles the case when token or groups are missing
  void _handleMissingPrerequisites() {
    errorMessage.value = !hasVkToken
        ? "Необходимо указать VK токен в настройках."
        : "Необходимо добавить хотя бы одну группу в настройках.";
    isLoading.value = false;
    isLoadingMore.value = false;
  }

  /// Fetches users from the repository
  Future<List<VKGroupUser>> _fetchUsersFromRepository() async {
    final Set<String> skippedIds = _statisticsController.skippedIdsSet;
    return await _groupUsersRepository.getUsers(vkToken, skippedIds.toList());
  }

  /// Processes newly fetched users
  void _processNewUsers(List<VKGroupUser> fetchedUsers, bool isInitialLoad) {
    final existingUserIds = users.map((u) => u.userID).toSet();
    final uniqueNewUsers = fetchedUsers
        .where((user) => !existingUserIds.contains(user.userID))
        .toList();

    if (uniqueNewUsers.isNotEmpty) {
      users.addAll(uniqueNewUsers);
      if (errorMessage.value != null) errorMessage.value = null;
      _saveCurrentStackWithDebounce();
    } else if (isInitialLoad && users.isEmpty) {
      errorMessage.value =
          "Не найдено новых пользователей по вашим критериям.\nПопробуйте изменить фильтры или обновить.";
    }
  }

  /// Handles errors during fetch operation
  void _handleFetchError(dynamic error, bool isInitialLoad) {
    final errorMsg = error.toString().replaceFirst('Exception: ', '');

    Get.snackbar(
      'Ошибка загрузки',
      errorMsg,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red[100],
      colorText: Colors.red[900],
      margin: const EdgeInsets.all(8),
      borderRadius: 10,
      duration: const Duration(seconds: 4),
    );

    if (isInitialLoad && users.isEmpty) {
      errorMessage.value = "Ошибка при загрузке: $errorMsg";
    }
  }

  /// Dismisses the top card with the given direction (like/dislike)
  Future<void> dismissCard(DismissDirection direction) async {
    // Skip if busy or no cards
    if (users.isEmpty ||
        isLoading.value ||
        isLoadingMore.value ||
        isSendingMessage.value ||
        _isApiFetchInProgress) {
      return;
    }

    // Process the dismissed card
    final dismissedUser = users.removeAt(0);
    final groupURL = dismissedUser.groupURL ?? "unknown_group";
    final actionType =
        direction == DismissDirection.startToEnd ? ActionLike : ActionDislike;

    // Record the action in statistics
    await _statisticsController.addUserAction(
        groupURL, dismissedUser, actionType);

    // Save the updated stack
    _saveCurrentStackWithDebounce();

    // Show message dialog for likes
    if (actionType == ActionLike) {
      showMessageDialogForUser(dismissedUser);
    }

    // Check if we need to fetch more cards
    _checkAndFetchMoreIfNeeded(delay: _fetchDebounceDuration);

    // Reset the loaded from disk flag
    if (_justLoadedFromDisk) {
      _justLoadedFromDisk = false;
    }
  }

  /// Checks if more cards need to be fetched and triggers a fetch if needed
  void _checkAndFetchMoreIfNeeded({Duration delay = Duration.zero}) {
    _fetchDebounceTimer?.cancel();

    // Skip if we just loaded from disk
    if (_justLoadedFromDisk) {
      return;
    }

    _fetchDebounceTimer = Timer(delay, () {
      if (isClosed) return;

      // Fetch more if card count is below threshold
      if (users.length < _loadMoreThreshold && !_isApiFetchInProgress) {
        _triggerApiFetch(isInitialLoad: false);
      }
    });
  }

  /// Saves the current stack with debounce to avoid frequent saves
  Future<void> _saveCurrentStackWithDebounce() async {
    _saveStackDebounceTimer?.cancel();
    _saveStackDebounceTimer = Timer(_saveStackDebounceDuration, () {
      _saveCurrentStackImmediate();
    });
  }

  /// Saves the current stack immediately
  Future<void> _saveCurrentStackImmediate() async {
    if (isClosed) return;

    final List<VKGroupUser> stackToSave = List.from(users); // Safe copy
    await _localStorageProvider.savePersistedCards(stackToSave);
  }

  /// Clears both persisted and in-memory card stack
  Future<void> _clearPersistedAndMemoryStack() async {
    users.clear(); // Clear memory
    await _localStorageProvider.clearPersistedCards(); // Clear disk
  }

  /// Sends a VK message to the specified user
  Future<bool> sendVKMessage(String userId, String message) async {
    // Validate inputs and state
    if (isSendingMessage.value) {
      return false;
    }

    if (userId.isEmpty || !hasVkToken) {
      _showErrorSnackbar('Не указан ID пользователя или VK токен.');
      return false;
    }

    if (message.isEmpty) {
      _showErrorSnackbar('Сообщение не может быть пустым.');
      return false;
    }

    bool success = false;
    try {
      isSendingMessage.value = true;
      success =
          await _groupUsersRepository.sendMessage(vkToken, userId, message);

      if (success && !isClosed) {
        _showSuccessSnackbar('Сообщение отправлено.');
      }
    } catch (e) {
      if (!isClosed) {
        _showErrorSnackbar('Не удалось отправить сообщение: ${e.toString()}');
      }
      success = false;
    } finally {
      if (!isClosed) {
        isSendingMessage.value = false;
      }
    }
    return success;
  }

  /// Shows a dialog to send a message to the specified user
  void showMessageDialogForUser(VKGroupUser targetUser) {
    final TextEditingController messageController =
        TextEditingController(text: defaultMessage);
    final RxBool isDialogSending = false.obs;

    Get.dialog(
      AlertDialog(
        title: const Text('Отправить сообщение'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _buildRecipientText(targetUser),
          const SizedBox(height: 16),
          _buildTextField(
              controller: messageController,
              labelText: 'Сообщение',
              hintText: 'Введите ваше сообщение...',
              icon: Icons.message_outlined,
              maxLines: 4)
        ]),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        actions: [
          TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Отмена')),
          Obx(() => ElevatedButton.icon(
              onPressed: isDialogSending.value
                  ? null
                  : () => _handleSendMessage(
                      targetUser, messageController, isDialogSending),
              icon: isDialogSending.value
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_outlined, size: 18),
              label:
                  Text(isDialogSending.value ? 'Отправка...' : 'Отправить'))),
        ],
      ),
      barrierDismissible: !isDialogSending.value,
    );
  }

  /// Handles the send message button click
  Future<void> _handleSendMessage(VKGroupUser targetUser,
      TextEditingController messageController, RxBool isDialogSending) async {
    final message = messageController.text.trim();
    if (message.isEmpty) {
      _showErrorSnackbar('Сообщение не может быть пустым.');
      return;
    }

    isDialogSending.value = true;
    Get.back(result: true);
    await sendVKMessage(targetUser.userID, message);
  }

  /// Builds the recipient text for the message dialog
  Widget _buildRecipientText(VKGroupUser targetUser) {
    return RichText(
        text: TextSpan(
            style: TextStyle(color: Get.theme.textTheme.bodyMedium?.color),
            children: [
          const TextSpan(text: 'Кому: '),
          TextSpan(
              text: '${targetUser.name} ${targetUser.surname}',
              style: const TextStyle(fontWeight: FontWeight.bold))
        ]));
  }

  /// Builds a text field with the specified parameters
  Widget _buildTextField(
      {required TextEditingController controller,
      required String labelText,
      required String hintText,
      required IconData icon,
      int maxLines = 1}) {
    return TextField(
        controller: controller,
        maxLines: maxLines,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20),
            labelText: labelText,
            hintText: hintText,
            filled: true,
            isDense: true,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[400]!)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: Get.theme.primaryColor, width: 1.5))));
  }

  /// Shows an error snackbar with the specified message
  void _showErrorSnackbar(String message) {
    Get.snackbar(
      'Ошибка',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red[100],
      colorText: Colors.red[900],
      margin: const EdgeInsets.all(8),
      borderRadius: 10,
      duration: const Duration(seconds: 4),
    );
  }

  /// Shows a success snackbar with the specified message
  void _showSuccessSnackbar(String message) {
    Get.snackbar(
      'Успех',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green[100],
      colorText: Colors.green[900],
      margin: const EdgeInsets.all(8),
      borderRadius: 10,
      duration: const Duration(seconds: 2),
    );
  }

  VoidCallback get refreshButtonAction =>
      () => loadCardsFromAPI(forceReload: true);
}

// --- File: lib/presentation/controllers/home_controller.dart ---
// lib/presentation/controllers/home_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vktinder/data/models/statistics.dart'; // ActionLike, ActionDislike
import 'package:vktinder/data/models/vk_group_user.dart';
import 'package:vktinder/presentation/controllers/settings_controller.dart';
import 'package:vktinder/data/repositories/group_users_repository_impl.dart';
import 'package:vktinder/presentation/controllers/statistics_controller.dart';

class HomeController extends GetxController {
  final SettingsController _settingsController = Get.find<SettingsController>();
  final GroupUsersRepository _groupUsersRepository =
  Get.find<GroupUsersRepository>();
  final StatisticsController _statisticsController =
  Get.find<StatisticsController>(); // Keep this

  final RxList<VKGroupUser> users = <VKGroupUser>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isSendingMessage = false.obs;
  final RxnString errorMessage = RxnString();
  final RxBool isLoadingMore = false.obs;

  String get vkToken => _settingsController.vkToken;
  String get defaultMessage => _settingsController.defaultMessage;
  bool get hasVkToken => vkToken.isNotEmpty;
  bool get hasGroupsConfigured => _settingsController.groupUrls.isNotEmpty;

  // Throttling for API calls
  DateTime? _lastApiCallTime;
  final Duration _apiCallThrottleDuration = const Duration(seconds: 3);


  @override
  void onInit() {
    super.onInit();
    // Initial load (no storage load needed anymore)
    loadCardsFromAPI(forceReload: true); // Start with a fresh load

    // Listen to settings changes - Debounce to avoid rapid reloads
    debounce(_settingsController.settingsChanged,
          (_) => loadCardsFromAPI(forceReload: true),
      time: const Duration(milliseconds: 500), // Wait 500ms after last change
    );

    // Listen for changes in skipped users and potentially trigger a load
    // if the current list becomes too small after a background update.
    ever(_statisticsController.skippedUserIDs, (_) {
      if (!isLoading.value && !isLoadingMore.value && users.length < 3) {
        print("Skipped IDs updated and user list is short. Checking for more users.");
        // Check throttle before automatic load
        _loadMoreIfNeeded(force: false);
      }
    });
  }

  // DEPRECATED: No longer loading from storage
  Future<void> loadCardsFromStorage() async {
    isLoading.value = true; // Still set loading true initially
    errorMessage.value = null;
    users.clear(); // Start empty
    // Immediately try loading from API
    await loadCardsFromAPI(forceReload: false); // forceReload might be true depending on context
    isLoading.value = false;
  }


  Future<void> loadCardsFromAPI({bool forceReload = false}) async {
    // Throttle API calls
    final now = DateTime.now();
    if (_lastApiCallTime != null && now.difference(_lastApiCallTime!) < _apiCallThrottleDuration && !forceReload) {
      print("API call throttled. Skipping.");
      return;
    }

    errorMessage.value = null;
    if (!hasVkToken) {
      users.clear();
      isLoading.value = false; // Ensure loading stops
      isLoadingMore.value = false;
      errorMessage.value = "Необходимо указать VK токен в настройках.";
      return;
    }
    if (!hasGroupsConfigured) {
      users.clear();
      isLoading.value = false; // Ensure loading stops
      isLoadingMore.value = false;
      errorMessage.value =
      "Необходимо добавить хотя бы одну группу в настройках.";
      return;
    }

    // Prevent concurrent loads
    if (isLoading.value || isLoadingMore.value) {
      print("Already loading. Skipping duplicate API call.");
      return;
    }

    if (forceReload) {
      errorMessage.value = null;
      users.clear();
      isLoading.value = true; // Set main loading indicator for force reload
      isLoadingMore.value = false;
    } else {
      // Don't fetch if we have enough cards and not forcing reload
      if (users.length >= 10) { // Increase buffer slightly
        print("Have enough cards (${users.length}), skipping background fetch.");
        return;
      }
      // Don't set isLoading.value = true if just loading more
      isLoadingMore.value = true;
      isLoading.value = false; // Ensure main loader is false if loading more
    }

    _lastApiCallTime = now; // Update last call time

    try {
      // Get the current set of skipped IDs (needed by repo)
      final skippedIds = _statisticsController.skippedIdsSet;
      print("Fetching new users, excluding ${skippedIds.length} skipped IDs...");

      // Fetch users using the repository method
      final fetchedUsers = await _groupUsersRepository.getUsers(
          vkToken,
          skippedIds.toList() // Pass skipped IDs
      );

      // Filter out users already present in the current list on the client side
      // (Repo filter should handle skipped IDs, but this handles duplicates from overlapping searches)
      final existingUserIds = users.map((u) => u.userID).toSet();
      final uniqueNewUsers = fetchedUsers
          .where((user) => !existingUserIds.contains(user.userID))
          .toList();

      print(
          "Fetched ${fetchedUsers.length} raw users from repo, ${uniqueNewUsers.length} are unique new users.");

      // Update the users list
      users.addAll(uniqueNewUsers); // Always add, forceReload cleared it already

      // No longer saving cards to local storage
      // await _groupUsersRepository.saveCards(users.toList());

      if (users.isEmpty && errorMessage.value == null && !isLoading.value && !isLoadingMore.value) {
        // Check loading states again before setting empty message
        errorMessage.value =
        "Не найдено новых пользователей по заданным критериям.\nПопробуйте изменить фильтры в настройках.";
      }


    } catch (e) {
      print("Error in HomeController.loadCardsFromAPI: $e");
      final errorMsg = e.toString().replaceFirst('Exception: ', '');
      Get.snackbar(
        'Ошибка загрузки',
        errorMsg,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
        margin: const EdgeInsets.all(8),
        borderRadius: 10,
        duration: const Duration(seconds: 5),
      );
      // If it failed and we have no users at all, show persistent error message
      if (users.isEmpty) {
        errorMessage.value = "Ошибка при загрузке: $errorMsg";
      }
    } finally {
      // Ensure both loading flags are reset
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  // Helper to trigger loading more users if needed, respecting throttle.
  void _loadMoreIfNeeded({bool force = false}) {
    if (users.length < 5 && !isLoading.value && !isLoadingMore.value) {
      final now = DateTime.now();
      if (force || _lastApiCallTime == null || now.difference(_lastApiCallTime!) >= _apiCallThrottleDuration) {
        print("User list short (${users.length}). Triggering background fetch.");
        // Using Future.delayed to avoid potential state conflicts during builds
        Future.delayed(const Duration(milliseconds: 50), () {
          loadCardsFromAPI(forceReload: false);
        });
      } else {
        print("Load more needed, but throttled.");
      }
    }
  }

  Future<bool> sendVKMessage(String userId, String message) async {
    if (userId.isEmpty || !hasVkToken) {
      Get.snackbar(
        'Ошибка',
        'Не указан ID пользователя или VK токен.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange[100],
        colorText: Colors.orange[900],
        margin: const EdgeInsets.all(8),
        borderRadius: 10,
      );
      return false;
    }
    if (message.isEmpty) {
      Get.snackbar(
        'Ошибка',
        'Сообщение не может быть пустым.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange[100],
        colorText: Colors.orange[900],
        margin: const EdgeInsets.all(8),
        borderRadius: 10,
      );
      return false;
    }

    final success =
    await _groupUsersRepository.sendMessage(vkToken, userId, message);

    // Feedback is now handled in the repository/API provider based on specific errors
    if (success) {
      Get.snackbar(
        'Успех',
        'Сообщение отправлено.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green[100],
        colorText: Colors.green[900],
        margin: const EdgeInsets.all(8),
        borderRadius: 10,
        duration: const Duration(seconds: 2),
      );
    }

    return success; // Return the result
  }

  // Helper for dialog text field
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData icon,
    int maxLines = 1,
  }) {
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
            borderSide: BorderSide(color: Colors.grey[300]!)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[400]!)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Get.theme.primaryColor, width: 1.5)),
      ),
    );
  }

  Future<void> dismissCard(DismissDirection direction) async {
    if (users.isEmpty) return;

    final dismissedUser = users.first;

    // 1. Remove card from UI immediately
    users.removeAt(0);

    // 2. NO local storage save needed anymore
    // await _groupUsersRepository.saveCards(users.toList());

    // 3. Perform action and update statistics
    final groupURL =
        dismissedUser.groupURL ?? "unknown_group"; // Handle null groupURL
    final actionType = direction == DismissDirection.startToEnd ? ActionLike : ActionDislike;

    // Update statistics controller (this also adds to skipped IDs internally)
    await _statisticsController.addUserAction(groupURL, dismissedUser, actionType);

    if (actionType == ActionLike) {
      // Show message dialog only on Like
      showMessageDialogForUser(dismissedUser);
    } else {
      print("Disliked user: ${dismissedUser.userID} from group $groupURL");
    }

    // 4. Check if need to load more users
    _loadMoreIfNeeded(); // Use helper function
    print("Dismiss ended for ${dismissedUser.userID}");
  }

  void showMessageDialogForUser(VKGroupUser targetUser) {
    // Check if messaging is possible (basic check, API handles actual privacy)
    // This check can be removed if `can_write_private_message` is unreliable or not needed pre-send
    // if (targetUser.canWritePrivateMessage == false) {
    //   Get.snackbar('Информация', 'Пользователь ограничил отправку личных сообщений.', snackPosition: SnackPosition.BOTTOM);
    //   return;
    // }

    final TextEditingController messageController =
    TextEditingController(text: defaultMessage);

    // Use a local RxBool for the dialog's sending state to avoid conflict
    final RxBool isDialogSending = false.obs;

    Get.dialog(
      AlertDialog(
        title: const Text('Отправить сообщение'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RichText(
              text: TextSpan(
                style: TextStyle(color: Get.theme.textTheme.bodyMedium?.color),
                children: [
                  const TextSpan(text: 'Кому: '),
                  TextSpan(
                    text: '${targetUser.name} ${targetUser.surname}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: messageController,
              labelText: 'Сообщение',
              hintText: 'Введите ваше сообщение...',
              icon: Icons.message_outlined,
              maxLines: 4,
            ),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Отмена'),
          ),
          Obx(() => ElevatedButton.icon( // Listen to the local dialog sending state
            onPressed: isDialogSending.value
                ? null
                : () async {
              final message = messageController.text.trim();
              if (message.isEmpty) {
                Get.snackbar(
                    'Ошибка', 'Сообщение не может быть пустым.',
                    snackPosition: SnackPosition.BOTTOM);
                return;
              }
              isDialogSending.value = true; // Start sending visual state
              Get.back(); // Close dialog first
              await sendVKMessage(targetUser.userID, message); // Send
              // isDialogSending.value = false; // No need to reset, dialog is closed
            },
            icon: isDialogSending.value
                ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send_outlined, size: 18),
            label:
            Text(isDialogSending.value ? 'Отправка...' : 'Отправить'),
          )),
        ],
      ),
      // Prevent closing dialog by tapping outside while potentially sending?
      // barrierDismissible: !isDialogSending.value, // Consider usability
    );
  }
}
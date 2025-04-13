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

  // ... other variables ...
  final RxList<VKGroupUser> users = <VKGroupUser>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isSendingMessage = false.obs;
  final RxnString errorMessage = RxnString();
  final RxBool isLoadingMore = false.obs;

  String get vkToken => _settingsController.vkToken;

  String get defaultMessage => _settingsController.defaultMessage;

  bool get hasVkToken => vkToken.isNotEmpty;

  bool get hasGroupsConfigured => _settingsController.groupUrls.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    // Load cards from storage first, then fetch more if needed
    loadCardsFromStorage();

    // Listen to settings changes
    ever(_settingsController.settingsChanged,
        (_) => loadCardsFromAPI(forceReload: true));

    // Listen for changes in skipped users to potentially refilter if needed immediately
    // (Though usually reloading via settingsChanged is sufficient)
    // ever(_statisticsController.skippedUserIDs, (_) {
    //   print("Skipped IDs changed, count: ${_statisticsController.skippedUserIDs.length}");
    // });
  }

  Future<void> loadCardsFromStorage() async {
    // ... (keep existing loadCardsFromStorage logic)
    isLoading.value = true;
    errorMessage.value = null;

    try {
      final storedCards = await _groupUsersRepository.getStoredCards();
      // *** Filter out already skipped users during loading from storage ***
      final skippedIds = _statisticsController.skippedIdsSet;
      final filteredStoredCards = storedCards
          .where((user) => !skippedIds.contains(user.userID))
          .toList();
      users.assignAll(filteredStoredCards);
      print(
          "Loaded ${users.length} cards from storage after filtering skipped.");

      if (users.length < 5) {
        if (users.isNotEmpty) {
          Future.delayed(const Duration(milliseconds: 300), () {
            loadCardsFromAPI(forceReload: false);
          });
        } else {
          await loadCardsFromAPI(forceReload: false);
        }
      }
    } catch (e) {
      print("Error loading cards from storage: $e");
      await loadCardsFromAPI(forceReload: false);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadCardsFromAPI({bool forceReload = false}) async {
    errorMessage.value = null;
    if (!hasVkToken) {
      users.clear();
      isLoading.value = false;
      errorMessage.value = "Необходимо указать VK токен в настройках.";
      await _groupUsersRepository.saveCards([]); // Clear storage
      return;
    }
    if (!hasGroupsConfigured) {
      users.clear();
      isLoading.value = false;
      errorMessage.value =
          "Необходимо добавить хотя бы одну группу в настройках.";
      await _groupUsersRepository.saveCards([]); // Clear storage
      return;
    }

    if (forceReload) {
      errorMessage.value = null;
      users.clear();
      // No need to clear storage here *if* we filter correctly on load
      // await _groupUsersRepository.saveCards([]); // Let's try without clearing here first
    }

    if (!forceReload && users.isNotEmpty && !isLoadingMore.value) {
      // Check isLoadingMore too
      // Don't fetch if we are already loading more or have enough cards
      if (users.length >= 5) {
        // Only return if we have a buffer
        print("Have enough cards (${users.length}), skipping API fetch.");
        return;
      }
    }

    if (users.isEmpty) {
      isLoading.value = true;
    } else {
      isLoadingMore.value = true;
    }

    try {
      // *** Get the current set of skipped IDs ***
      final skippedIds = _statisticsController.skippedIdsSet;
      print(
          "Fetching new users, excluding ${skippedIds.length} skipped IDs (example: ${skippedIds.take(5).join(',')})");

      // Pass empty list to getUsers for now, as filtering happens in repo with users.search
      // OR modify repo's getUsers to accept skippedIds Set
      // Let's keep the repo change minimal for now and filter *after* fetching.

      // Fetch users using the repository method (which now uses users.search)
      final fetchedUsers = await _groupUsersRepository.getUsers(
          vkToken,
          // Pass the skipped IDs from the statistics controller
          // The repository's getUsers method already uses this
          skippedIds.toList() // Convert Set to List for the repo method
          );

      // Filter out any skipped users that might have slipped through (e.g., if API doesn't filter perfectly)
      final newUsers = fetchedUsers
          .where((user) => !skippedIds.contains(user.userID))
          .toList();

      // Also filter out users already present in the current list
      final existingUserIds = users.map((u) => u.userID).toSet();
      final uniqueNewUsers = newUsers
          .where((user) => !existingUserIds.contains(user.userID))
          .toList();

      print(
          "Fetched ${fetchedUsers.length} raw users, ${newUsers.length} after skipped filter, ${uniqueNewUsers.length} unique new users added.");

      if (forceReload) {
        users.assignAll(uniqueNewUsers); // Replace if force reload
      } else {
        users.addAll(uniqueNewUsers); // Add unique new users
      }

      // Save only the current visible/swipable cards to storage
      await _groupUsersRepository.saveCards(users.toList());

      if (users.isEmpty && errorMessage.value == null) {
        errorMessage.value =
            "Не найдено новых пользователей по заданным критериям.\nПопробуйте изменить фильтры в настройках.";
      }
    } catch (e) {
      print("Error in HomeController.loadCards: $e");
      Get.snackbar(
        'Ошибка загрузки',
        e.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
        margin: const EdgeInsets.all(8),
        borderRadius: 10,
        duration: const Duration(seconds: 5),
      );
      if (users.isEmpty) {
        // If it failed and we have no users, show error message
        errorMessage.value =
            "Ошибка при загрузке: ${e.toString().replaceFirst('Exception: ', '')}";
      }
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  // ... sendVKMessage and _buildTextField remain the same ...
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

    isSendingMessage.value = true; // Indicate sending started (used in dialog)
    final success =
        await _groupUsersRepository.sendMessage(vkToken, userId, message);
    isSendingMessage.value = false; // Indicate sending finished

    // Show feedback based on result (moved from dialog to here)
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
    // Error snackbars are now shown directly from the apiProvider/repository
    // else {
    //    Get.snackbar(
    //      'Ошибка', 'Не удалось отправить сообщение.',
    //      snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red[100], colorText: Colors.red[900], margin: const EdgeInsets.all(8), borderRadius: 10, duration: const Duration(seconds: 3),
    //    );
    // }

    return success; // Return the result
  }

  // Helper (similar to settings page) for dialog text field
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
            // Ensure border is consistent
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

    // 2. Save the *reduced* list to storage (potentially could be optimized further)
    await _groupUsersRepository.saveCards(users.toList());

    // 3. Perform action and update statistics
    final groupURL =
        dismissedUser.groupURL ?? "unknown_group"; // Handle null groupURL
    if (direction == DismissDirection.startToEnd) {
      // Like
      //showMessageDialogForUser(dismissedUser); // Show message dialog
      // *** Pass necessary user fields and action type to statistics controller ***
      await _statisticsController.addUserAction(
          groupURL, dismissedUser, ActionLike);
    } else {
      // Dislike
      print("Disliked user: ${dismissedUser.userID} from group $groupURL");
      // *** Pass necessary user fields and action type to statistics controller ***
      await _statisticsController.addUserAction(
          groupURL, dismissedUser, ActionDislike);
    }

    // 4. Check if need to load more users
    if (users.length < 3 && !isLoading.value && !isLoadingMore.value) {
      print("User list short (${users.length}). Triggering background fetch.");
      // No need to set isLoadingMore = true here, loadCardsFromAPI handles it
      // Using Future.delayed prevents potential state conflicts if dismiss is rapid
      Future.delayed(const Duration(milliseconds: 100), () {
        loadCardsFromAPI(forceReload: false);
      });
    }
    print("Dismiss ended for ${dismissedUser.userID}");
  }

  // ... showMessageDialogForUser remains the same ...
  void showMessageDialogForUser(VKGroupUser targetUser) {
    // This is almost identical to showMessageDialog, but uses targetUser
    // and calls the sendVKMessage method directly.
    final TextEditingController messageController =
        TextEditingController(text: defaultMessage);

    Get.dialog(
      AlertDialog(
        title: const Text('Отправить сообщение'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RichText(
              /* ... as before ... using targetUser.name/surname */
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
          Obx(() => ElevatedButton.icon(
                onPressed: isSendingMessage.value
                    ? null
                    : () async {
                        final message = messageController.text.trim();
                        if (message.isEmpty) {
                          Get.snackbar(
                              'Ошибка', 'Сообщение не может быть пустым.',
                              snackPosition: SnackPosition.BOTTOM);
                          return;
                        }
                        Get.back(); // Close dialog
                        await sendVKMessage(targetUser.userID, message); // Send
                      },
                icon: isSendingMessage.value
                    ? /* spinner */ const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_outlined, size: 18),
                label:
                    Text(isSendingMessage.value ? 'Отправка...' : 'Отправить'),
              )),
        ],
      ),
      // Prevent closing dialog by tapping outside while sending? Optional.
      // barrierDismissible: !isSendingMessage.value,
    );
  }
}

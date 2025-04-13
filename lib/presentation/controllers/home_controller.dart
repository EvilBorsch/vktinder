import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vktinder/data/models/statistics.dart';
import 'package:vktinder/data/models/vk_group_user.dart';
import 'package:vktinder/presentation/controllers/settings_controller.dart';
import 'package:vktinder/data/repositories/group_users_repository_impl.dart';
import 'package:vktinder/presentation/controllers/statistics_controller.dart';

class HomeController extends GetxController {
  final SettingsController _settingsController = Get.find<SettingsController>();
  final GroupUsersRepository _groupUsersRepository =
      Get.find<GroupUsersRepository>();
  final StatisticsController _statisticsController =
      Get.find<StatisticsController>();

  // Reactive variables
  final RxList<VKGroupUser> users = <VKGroupUser>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isSendingMessage =
      false.obs; // Keep for message sending UI state
  final RxnString errorMessage =
      RxnString(); // For displaying persistent errors
  final RxBool isLoadingMore = false.obs; // For loading more cards

  // Getters
  String get vkToken => _settingsController.vkToken;

  String get defaultMessage => _settingsController.defaultMessage;

  bool get hasVkToken => vkToken.isNotEmpty;

  // Check if group URLs are configured
  bool get hasGroupsConfigured => _settingsController.groupUrls.isNotEmpty;

  @override
  void onInit() {
    super.onInit();

    // Load cards from storage first, then fetch more if needed
    loadCardsFromStorage();

    // Listen to settings changes (token, cities, age, groups) and reload cards
    // Use the consolidated `settingsChanged` signal
    ever(_settingsController.settingsChanged,
        (_) => loadCardsFromAPI(forceReload: true));
  }

  // Load cards from storage first
  Future<void> loadCardsFromStorage() async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      final storedCards = await _groupUsersRepository.getStoredCards();
      users.assignAll(storedCards);

      // If we have few or no cards, fetch more from API but with a slight delay
      // to ensure the UI is responsive first
      if (users.length < 5) {
        if (users.isNotEmpty) {
          // If we have some cards, delay the API call to allow interaction
          Future.delayed(const Duration(milliseconds: 300), () {
            loadCardsFromAPI(forceReload: false);
          });
        } else {
          // If no cards, load immediately
          await loadCardsFromAPI(forceReload: false);
        }
      }
    } catch (e) {
      print("Error loading cards from storage: $e");
      // If storage loading fails, try API
      await loadCardsFromAPI(forceReload: false);
    } finally {
      isLoading.value = false;
    }
  }

  // Load cards from API
  Future<void> loadCardsFromAPI({bool forceReload = false}) async {
    errorMessage.value = null; // Clear previous errors
    if (!hasVkToken) {
      users.clear();
      isLoading.value = false;
      errorMessage.value = "Необходимо указать VK токен в настройках.";
      // Clear storage when token is missing
      await _groupUsersRepository.saveCards([]);
      return;
    }
    if (!hasGroupsConfigured) {
      users.clear();
      isLoading.value = false;
      errorMessage.value =
          "Необходимо добавить хотя бы одну группу в настройках.";
      // Clear storage when no groups are configured
      await _groupUsersRepository.saveCards([]);
      return;
    }

    // If we're forcing a reload, clear the error message and existing users
    if (forceReload) {
      errorMessage.value = null;
      // When settings change, we want to start fresh
      users.clear();
      // Clear storage when forcing reload (usually due to settings change)
      await _groupUsersRepository.saveCards([]);
    }

    // If we already have cards and aren't forcing a reload, don't fetch more
    if (!forceReload && users.isNotEmpty) {
      return;
    }

    // Set loading state
    if (users.isEmpty) {
      isLoading.value = true; // Full loading state if no cards
    } else {
      isLoadingMore.value = true; // "Loading more" state if we have cards
    }
    try {
      // getUsers now uses the settings implicitly via the repository
      final fetchedUsers = await _groupUsersRepository.getUsers(
          vkToken, _statisticsController.skippedUserIDs);

      if (forceReload) {
        // Replace all cards if forcing reload
        users.assignAll(fetchedUsers);
      } else {
        // Add new cards to the end of the existing list
        users.addAll(fetchedUsers);
      }

      // Save the updated list to storage
      await _groupUsersRepository.saveCards(users.toList());
      if (users.isEmpty && errorMessage.value == null) {
        errorMessage.value =
            "Не найдено пользователей по заданным критериям.\nПопробуйте изменить фильтры в настройках.";
      }
    } catch (e) {
      print("Error in HomeController.loadCards: $e");
      Get.snackbar(
        'Ошибка загрузки',
        e
            .toString()
            .replaceFirst('Exception: ', ''), // Clean up exception message
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
        margin: const EdgeInsets.all(8),
        borderRadius: 10,
        duration: const Duration(seconds: 5),
      );
      users.clear();
      errorMessage.value =
          "Ошибка при загрузке: ${e.toString().replaceFirst('Exception: ', '')}";
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  // sendVKMessage remains the same
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

  // dismissCard with persistence
  Future<void> dismissCard(DismissDirection direction) async {
    if (users.isEmpty) return;

    // Get user *before* removing
    final dismissedUser = users.first;

    // 1. Remove card from UI immediately for responsiveness
    users.removeAt(0);

    // 2. Save the updated list to storage
    await _groupUsersRepository.saveCards(users.toList());

    // 3. Perform action based on swipe direction (after UI update)
    if (direction == DismissDirection.startToEnd) {
      // Message action - Show dialog (which now handles sending)
      showMessageDialogForUser(dismissedUser); // Pass dismissed user
      _statisticsController.addUserAction(dismissedUser.groupURL.toString(), StatisticsUserAction(dismissedUser, ActionLike, DateTime.now()));
    } else {
      // Dislike action - currently does nothing backend-wise
      print("Disliked user: ${dismissedUser.userID}");
      _statisticsController.addUserAction(dismissedUser.groupURL.toString(), StatisticsUserAction(dismissedUser, ActionDislike, DateTime.now()));
    }

    // 4. Check if need to load more users
    if (users.length < 3 && !isLoading.value && !isLoadingMore.value) {
      print("User list short (${users.length}). Triggering background fetch.");
      // Trigger a background load, but don't block the UI
      isLoadingMore.value = true;

      // Use a slight delay to ensure UI updates first
      Future.delayed(const Duration(milliseconds: 300), () {
        loadCardsFromAPI(forceReload: false).catchError((e) {
          print("Background loadCards failed: $e");
        }).whenComplete(() {
          isLoadingMore.value = false;
        });
      });
    }
  }

  // Modified message dialog to accept user explicitly
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
                          /* show snackbar */ return;
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

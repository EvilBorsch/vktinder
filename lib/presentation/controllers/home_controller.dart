import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vktinder/data/models/vk_group_user.dart';
import 'package:vktinder/presentation/controllers/settings_controller.dart';
import 'package:vktinder/data/repositories/group_users_repository_impl.dart';

class HomeController extends GetxController {
  final SettingsController _settingsController = Get.find<SettingsController>();
  final GroupUsersRepository _groupUsersRepository = Get.find<GroupUsersRepository>();

  // Reactive variables
  final RxList<VKGroupUser> users = <VKGroupUser>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isSendingMessage = false.obs; // Keep for message sending UI state
  final RxnString errorMessage = RxnString(); // For displaying persistent errors

  // Getters
  String get vkToken => _settingsController.vkToken;
  String get defaultMessage => _settingsController.defaultMessage;
  bool get hasVkToken => vkToken.isNotEmpty;
  // Check if group URLs are configured
  bool get hasGroupsConfigured => _settingsController.groupUrls.isNotEmpty;

  @override
  void onInit() {
    super.onInit();

    // Load cards initially
    loadCards();

    // Listen to settings changes (token, cities, age, groups) and reload cards
    // Use the consolidated `settingsChanged` signal
    ever(_settingsController.settingsChanged, (_) => loadCards());
  }

  Future<void> loadCards() async {
    errorMessage.value = null; // Clear previous errors
    if (!hasVkToken) {
      users.clear();
      isLoading.value = false;
      errorMessage.value = "Необходимо указать VK токен в настройках.";
      return;
    }
    if (!hasGroupsConfigured) {
      users.clear();
      isLoading.value = false;
      errorMessage.value = "Необходимо добавить хотя бы одну группу в настройках.";
      return;
    }

    isLoading.value = true;
    try {
      // getUsers now uses the settings implicitly via the repository
      final fetchedUsers = await _groupUsersRepository.getUsers(vkToken);
      // Shuffle the results for a Tinder-like random order
      fetchedUsers.shuffle();
      users.assignAll(fetchedUsers); // Use assignAll for reactive update
      if (users.isEmpty && errorMessage.value == null) {
        errorMessage.value = "Не найдено пользователей по заданным критериям.\nПопробуйте изменить фильтры в настройках.";
      }
    } catch (e) {
      print("Error in HomeController.loadCards: $e");
      Get.snackbar(
        'Ошибка загрузки',
        e.toString().replaceFirst('Exception: ', ''), // Clean up exception message
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
        margin: const EdgeInsets.all(8),
        borderRadius: 10,
        duration: const Duration(seconds: 5),
      );
      users.clear();
      errorMessage.value = "Ошибка при загрузке: ${e.toString().replaceFirst('Exception: ', '')}";
    } finally {
      isLoading.value = false;
    }
  }

  // sendVKMessage remains the same
  Future<bool> sendVKMessage(String userId, String message) async {
    if (userId.isEmpty || !hasVkToken) {
      Get.snackbar(
        'Ошибка',
        'Не указан ID пользователя или VK токен.',
        snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange[100], colorText: Colors.orange[900], margin: const EdgeInsets.all(8), borderRadius: 10,
      );
      return false;
    }
    if (message.isEmpty) {
      Get.snackbar(
        'Ошибка',
        'Сообщение не может быть пустым.',
        snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange[100], colorText: Colors.orange[900], margin: const EdgeInsets.all(8), borderRadius: 10,
      );
      return false;
    }


    isSendingMessage.value = true; // Indicate sending started (used in dialog)
    final success = await _groupUsersRepository.sendMessage(vkToken, userId, message);
    isSendingMessage.value = false; // Indicate sending finished

    // Show feedback based on result (moved from dialog to here)
    if (success) {
      Get.snackbar(
        'Успех', 'Сообщение отправлено.',
        snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green[100], colorText: Colors.green[900], margin: const EdgeInsets.all(8), borderRadius: 10, duration: const Duration(seconds: 2),
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

  // showMessageDialog remains largely the same, just uses the updated sendVKMessage
  void showMessageDialog() {
    if (users.isEmpty) return;

    final currentUser = users.first;
    final TextEditingController messageController =
    TextEditingController(text: defaultMessage); // Use getter for default message

    Get.dialog(
      AlertDialog(
        title: const Text(
          'Отправить сообщение',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RichText(
              text: TextSpan(
                style: TextStyle(color: Get.theme.textTheme.bodyMedium?.color),
                children: [
                  const TextSpan(text: 'Кому: '),
                  TextSpan(
                    text: '${currentUser.name} ${currentUser.surname}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField( // Use helper for consistency
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
            child: const Text('Отмена'), // Simplified style
          ),
          // Use a separate Obx for the button state only
          Obx(() => ElevatedButton.icon(
            onPressed: isSendingMessage.value
                ? null // Disable button while sending
                : () async {
              final message = messageController.text.trim();
              if (message.isEmpty) {
                Get.snackbar(
                  'Ошибка',
                  'Сообщение не может быть пустым.',
                  snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange[100], colorText: Colors.orange[900], margin: const EdgeInsets.all(8), borderRadius: 10,
                );
                return;
              }
              // Close dialog *before* sending async operation
              Get.back();
              // Asynchronously send message
              await sendVKMessage(currentUser.userID, message);
              // Snackbar feedback is now handled within sendVKMessage
            },
            icon: isSendingMessage.value
                ? Container( // Show spinner inside button
                width: 18, height: 18,
                padding: const EdgeInsets.all(2.0),
                child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send_outlined, size: 18),
            label: Text(isSendingMessage.value ? 'Отправка...' : 'Отправить'),
          )),
        ],
      ),
    );
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
        border: OutlineInputBorder( // Ensure border is consistent
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!)
        ),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[400]!)
        ),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Get.theme.primaryColor, width: 1.5)
        ),
      ),
    );
  }

  // dismissCard needs adjustment - reload might not be automatic anymore
  Future<void> dismissCard(DismissDirection direction) async {
    if (users.isEmpty) return;

    // Get user *before* removing
    final dismissedUser = users.first;

    // 1. Remove card from UI immediately for responsiveness
    users.removeAt(0);

    // 2. Perform action based on swipe direction (after UI update)
    if (direction == DismissDirection.startToEnd) {
      // Message action - Show dialog (which now handles sending)
      showMessageDialogForUser(dismissedUser); // Pass dismissed user
    } else {
      // Dislike action - currently does nothing backend-wise
      print("Disliked user: ${dismissedUser.userID}");
    }

    // 3. Check if need to load more users
    if (users.length < 3 && !isLoading.value) { // Load more if few users left and not already loading
      print("User list short (${users.length}). Triggering background fetch.");
      // Trigger a background load, but don't block the UI
      // Don't await this, let it run in the background
      loadCards().catchError((e) {
        print("Background loadCards failed: $e");
        // Optionally show a non-blocking error message
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
            RichText( /* ... as before ... using targetUser.name/surname */
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
            onPressed: isSendingMessage.value ? null : () async {
              final message = messageController.text.trim();
              if (message.isEmpty) { /* show snackbar */ return; }
              Get.back(); // Close dialog
              await sendVKMessage(targetUser.userID, message); // Send
            },
            icon: isSendingMessage.value ? /* spinner */ const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send_outlined, size: 18),
            label: Text(isSendingMessage.value ? 'Отправка...' : 'Отправить'),
          )),
        ],
      ),
      // Prevent closing dialog by tapping outside while sending? Optional.
      // barrierDismissible: !isSendingMessage.value,
    );
  }
}


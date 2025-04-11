import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vktinder/data/models/vk_group_user.dart';
import 'package:vktinder/presentation/controllers/settings_controller.dart';
import 'package:vktinder/data/repositories/group_users_repository_impl.dart';

class HomeController extends GetxController {
  final SettingsController _settingsController = Get.find<SettingsController>();
  final GroupUsersRepository _groupUsersRepository =
  Get.find<GroupUsersRepository>();

  // Reactive variables
  final RxList<VKGroupUser> users = <VKGroupUser>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isSendingMessage = false.obs;

  // Getters
  String get vkToken => _settingsController.vkToken;
  String get defaultMessage => _settingsController.defaultMessage;
  bool get hasVkToken => vkToken.isNotEmpty;

  @override
  void onInit() {
    super.onInit();

    // Load cards when controller initializes
    loadCards();

    // Listen to settings changes and reload cards if needed
    ever(_settingsController.tokenChange, (_) => loadCards());
  }

  Future<void> loadCards() async {
    if (!hasVkToken) {
      users.clear();
      isLoading.value = false;
      return;
    }

    isLoading.value = true;
    try {
      users.value = await _groupUsersRepository.getUsers(vkToken);
    } catch (e) {
      Get.snackbar(
        'Ошибка',
        'Не удалось загрузить пользователей: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
        margin: const EdgeInsets.all(8),
        borderRadius: 10,
        duration: const Duration(seconds: 3),
      );
      users.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> sendVKMessage(String userId, String message) async {
    if (userId.isEmpty || !hasVkToken) return false;

    return await _groupUsersRepository.sendMessage(vkToken, userId, message);
  }

  void showMessageDialog() {
    if (users.isEmpty) return;

    final currentUser = users.first;
    final TextEditingController messageController =
    TextEditingController(text: defaultMessage);

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
                  const TextSpan(text: 'Сообщение для '),
                  TextSpan(
                    text: '${currentUser.name} ${currentUser.surname}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: 'Сообщение',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.message),
              ),
              maxLines: 3,
            ),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Отмена', style: TextStyle(fontSize: 16)),
          ),
          Obx(() => ElevatedButton.icon(
            onPressed: isSendingMessage.value
                ? null
                : () async {
              isSendingMessage.value = true;

              // Close dialog immediately
              Get.back();

              // Send message after dialog is closed
              final success = await sendVKMessage(
                  currentUser.userID, messageController.text);

              if (success) {
                Get.snackbar(
                  'Успех',
                  'Сообщение отправлено',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.green[100],
                  colorText: Colors.green[900],
                  margin: const EdgeInsets.all(8),
                  borderRadius: 10,
                  duration: const Duration(seconds: 2),
                );
              } else {
                Get.snackbar(
                  'Ошибка',
                  'Не удалось отправить сообщение',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red[100],
                  colorText: Colors.red[900],
                  margin: const EdgeInsets.all(8),
                  borderRadius: 10,
                  duration: const Duration(seconds: 2),
                );
              }

              isSendingMessage.value = false;
            },
            icon: const Icon(Icons.send),
            label: Text(
                isSendingMessage.value ? 'Отправка...' : 'Отправить',
                style: const TextStyle(fontSize: 16)),
          )),
        ],
      ),
    );
  }

  Future<void> dismissCard(DismissDirection direction) async {
    if (users.isEmpty) return;

    // If swiped right, show message dialog
    if (direction == DismissDirection.startToEnd) {
      showMessageDialog();
    }

    // Remove card and load new users
    isLoading.value = true;
    users.value =
    await _groupUsersRepository.removeFirstUser(vkToken, users.toList());
    isLoading.value = false;
  }
}

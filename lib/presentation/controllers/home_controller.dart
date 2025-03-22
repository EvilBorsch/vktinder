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
        'Failed to load users: ${e.toString()}',
        snackPosition: SnackPosition.TOP,
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

  Future<bool> sendVKMessage(String message) async {
    if (users.isEmpty || !hasVkToken) return false;

    // In a real app, you'd send the message to the specific user
    final userId = users.first.name;
    return await _groupUsersRepository.sendMessage(vkToken, userId, message);
  }

  void showMessageDialog() {
    final TextEditingController messageController =
        TextEditingController(text: defaultMessage);

    // Using simpler dialog pattern to avoid issues
    showDialog(
      context: Get.context!,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: const Text(
          'Отправить сообщение',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Напишите сообщение пользователю:',
              style: TextStyle(color: Colors.grey),
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
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена', style: TextStyle(fontSize: 16)),
          ),
          Obx(() => ElevatedButton.icon(
                onPressed: isSendingMessage.value
                    ? null
                    : () async {
                        isSendingMessage.value = true;

                        // Close dialog immediately
                        Navigator.of(context).pop();

                        // Send message after dialog is closed
                        final success =
                            await sendVKMessage(messageController.text);

                        if (success) {
                          Get.snackbar(
                            'Успех',
                            'Сообщение отправлено',
                            snackPosition: SnackPosition.TOP,
                            backgroundColor: Colors.green[100],
                            colorText: Colors.green[900],
                            margin: const EdgeInsets.all(8),
                            borderRadius: 10,
                            duration: const Duration(seconds: 1),
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

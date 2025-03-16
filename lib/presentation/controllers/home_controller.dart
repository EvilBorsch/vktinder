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
        'Error',
        'Failed to load users: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
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

  Future<void> showMessageDialog() async {
    final TextEditingController messageController = TextEditingController(
      text: defaultMessage,
    );

    return Get.dialog(
      AlertDialog(
        title: const Text('Отправить сообщение'),
        content: TextField(
          controller: messageController,
          decoration: const InputDecoration(
            labelText: 'Сообщение',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              final success = await sendVKMessage(messageController.text);
              Get.back(result: success);
            },
            child: const Text('Отправить'),
          ),
        ],
      ),
    );
  }

  Future<void> dismissCard(DismissDirection direction) async {
    if (users.isEmpty) return;

    // If swiped right, show message dialog
    if (direction == DismissDirection.startToEnd) {
      await showMessageDialog();
    }

    // Remove the card regardless of swipe direction
    users.value =
        await _groupUsersRepository.removeFirstUser(vkToken, users.toList());
  }
}

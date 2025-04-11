import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vktinder/data/models/vk_group_user.dart';
import 'package:vktinder/presentation/controllers/settings_controller.dart';
import 'package:vktinder/data/repositories/group_users_repository_impl.dart';

class UserDetailsController extends GetxController {
  final Rx<VKGroupUser?> user = Rx<VKGroupUser?>(null);
  final RxBool isLoading = true.obs;
  final RxBool isSendingMessage = false.obs;

  final SettingsController _settingsController = Get.find<SettingsController>();
  final GroupUsersRepository _groupUsersRepository =
  Get.find<GroupUsersRepository>();

  @override
  void onInit() {
    super.onInit();
    final targetUser = Get.arguments as VKGroupUser;
    loadFullProfile(targetUser.userID);
  }

  Future<void> loadFullProfile(String userID) async {
    try {
      isLoading.value = true;
      final userDetails = await _groupUsersRepository.getFullProfile(
        _settingsController.vkToken,
        userID,
      );
      user.value = userDetails;
    } catch (e) {
      Get.snackbar(
        'Ошибка',
        'Не удалось загрузить полный профиль: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
        margin: const EdgeInsets.all(8),
        borderRadius: 10,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }

  void openVkProfile() async {
    if (user.value == null) return;
    
    final userId = user.value!.userID;
    final url = 'https://vk.com/id$userId';
    
    try {
      final uri = Uri.parse(url);
      // Try to launch in the VK app first
      bool launched = false;
      
      if (Platform.isAndroid) {
        // Try to launch VK app on Android
        try {
          launched = await launchUrl(
            Uri.parse('vk://profile/$userId'),
            mode: LaunchMode.externalApplication,
          );
        } catch (e) {
          print("Could not launch VK app: $e");
        }
      } else if (Platform.isIOS) {
        // Try to launch VK app on iOS
        try {
          launched = await launchUrl(
            Uri.parse('vk://vk.com/id$userId'),
            mode: LaunchMode.externalApplication,
          );
        } catch (e) {
          print("Could not launch VK app: $e");
        }
      }
      
      // If app launch failed, open in browser
      if (!launched) {
        await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Ошибка',
        'Не удалось открыть профиль VK: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
        margin: const EdgeInsets.all(8),
        borderRadius: 10,
        duration: const Duration(seconds: 3),
      );
    }
  }

  void sendMessage() {
    if (user.value == null) return;

    final TextEditingController messageController =
    TextEditingController(text: _settingsController.defaultMessage);

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
                    text: '${user.value?.name} ${user.value?.surname}',
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

              // Send message
              final success = await _groupUsersRepository.sendMessage(
                _settingsController.vkToken,
                user.value!.userID,
                messageController.text,
              );

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
}

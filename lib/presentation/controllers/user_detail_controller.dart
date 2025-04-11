import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vktinder/data/models/vk_group_user.dart';
import 'package:vktinder/data/models/vk_group_info.dart';
import 'package:vktinder/presentation/controllers/settings_controller.dart';
import 'package:vktinder/data/repositories/group_users_repository_impl.dart';

class UserDetailsController extends GetxController {
  final Rx<VKGroupUser?> user = Rx<VKGroupUser?>(null);
  final RxBool isLoading = true.obs;
  final RxBool isSendingMessage = false.obs;

  // Add separate observables for photos and groups
  final RxList<String> photos = <String>[].obs;
  final RxList<VKGroupInfo> groups = <VKGroupInfo>[].obs;

  final SettingsController _settingsController = Get.find<SettingsController>();
  final GroupUsersRepository _groupUsersRepository = Get.find<GroupUsersRepository>();

  @override
  void onInit() {
    super.onInit();
    final targetUser = Get.arguments as VKGroupUser;
    // Initialize the user with the basic info we already have
    user.value = targetUser;

    // Initialize photos and groups with any existing data
    photos.assignAll(targetUser.photos);
    groups.assignAll(targetUser.groups);

    // Set isLoading to false initially since we already have basic info
    isLoading.value = false;
  }

  @override
  void onReady() {
    super.onReady();
    // Only load the full profile when the page is actually shown
    final targetUser = Get.arguments as VKGroupUser;
    // Set loading state to true before fetching full profile
    isLoading.value = true;
    loadFullProfile(targetUser.userID);
  }

  Future<void> loadFullProfile(String userID) async {
    try {
      isLoading.value = true;
      final userDetails = await _groupUsersRepository.getFullProfile(
        _settingsController.vkToken,
        userID,
      );

      // Update separate observables first
      photos.assignAll(userDetails.photos);
      groups.assignAll(userDetails.groups);

      // Then update the user object itself
      user.value = userDetails;

      // Print debug info
      print("Loaded full profile - Photos: ${photos.length}, Groups: ${groups.length}");

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
      bool launched = false;

      // Handle platform-specific behavior
      if (kIsWeb) {
        // For web, just open in a new tab
        launched = false;
      } else {
        // On mobile platforms, try to launch the VK app first
        try {
          // Try Android deep link
          try {
            launched = await launchUrl(
              Uri.parse('vk://profile/$userId'),
              mode: LaunchMode.externalApplication,
            );
          } catch (e) {
            print("Could not launch Android VK app: $e");
          }

          // If Android didn't work, try iOS deep link
          if (!launched) {
            try {
              launched = await launchUrl(
                Uri.parse('vk://vk.com/id$userId'),
                mode: LaunchMode.externalApplication,
              );
            } catch (e) {
              print("Could not launch iOS VK app: $e");
            }
          }
        } catch (e) {
          print("Could not launch VK app: $e");
        }
      }

      // If app launch failed or we're on web, open in browser
      if (!launched) {
        if (kIsWeb) {
          // For web, use default mode
          await launchUrl(uri);
        } else {
          // For mobile, use external application
          await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
        }
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

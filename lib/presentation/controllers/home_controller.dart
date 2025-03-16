import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vktinder/data/models/vk_group_user.dart';
import 'package:vktinder/domain/usecases/group_users_usecase.dart';
import 'package:vktinder/presentation/controllers/settings_controller.dart';

class HomeController extends GetxController {
  final SettingsController settingsController = Get.find<SettingsController>();
  final GroupUsersUsecase usecase = Get.find<GroupUsersUsecase>();

  final _groupUserInfo = <VKGroupUser>[].obs;
  final _isLoading = true.obs;

  List<VKGroupUser> get groupUserInfo => _groupUserInfo;
  bool get isLoading => _isLoading.value;

  @override
  void onInit() {
    super.onInit();
    loadCards();

    // Listen to settings changes using the public settings property
    ever(settingsController.settings, (_) => loadCards());
  }

  Future<void> loadCards() async {
    _isLoading.value = true;
    _groupUserInfo.value = await usecase.get(
      settingsController.vkToken,
    );
    _isLoading.value = false;
  }

  Future<void> sendVKMessage(String msg) async {
    // Replace with real messaging logic if needed
    debugPrint("Sending message to VK: $msg");
  }

  Future<void> showSwipeDialog() async {
    final TextEditingController inputController = TextEditingController(
      text: settingsController.defaultMessage,
    );

    return Get.dialog(
      AlertDialog(
        title: const Text('Что напишем?'),
        content: TextField(
          controller: inputController,
          decoration: const InputDecoration(
            labelText: 'Сообщение',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Не писать'),
          ),
          TextButton(
            onPressed: () {
              sendVKMessage(inputController.text);
              Get.back();
            },
            child: const Text('Отправить'),
          ),
        ],
      ),
    );
  }

  Future<void> dismissTopCard(DismissDirection dir) async {
    if (dir == DismissDirection.startToEnd) {
      await showSwipeDialog();
    }
    _groupUserInfo.value = await usecase.removeFirst(
      settingsController.vkToken,
      List.from(_groupUserInfo),
    );
  }
}
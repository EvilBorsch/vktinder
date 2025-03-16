import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vktinder/presentation/controllers/home_controller.dart';
import 'package:vktinder/presentation/widgets/user_preview.dart';
import 'package:vktinder/routes/app_pages.dart';

class HomePage extends GetView {
  HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('VK Tinder')),
      body: Obx(() {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.settingsController.vkToken.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                "Задайте VK Token в настройках",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          );
        }

        return Column(
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: List.generate(controller.groupUserInfo.length, (index) {
                  final cardIndex = controller.groupUserInfo.length - 1 - index;
                  final cardUserInfo = controller.groupUserInfo[cardIndex];
                  return Dismissible(
                    key: ValueKey(cardUserInfo.toString()),
                    direction: DismissDirection.horizontal,
                    resizeDuration: null,
                    onDismissed: (dir) => controller.dismissTopCard(dir),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: VKGroupUserWidget(userInfo: cardUserInfo),
                    ),
                  );
                }),
              ),
            ),
          ],
        );
      }),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (idx) {
          if (idx == 1) {
            Get.toNamed(Routes.SETTINGS);
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Главная'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Настройки',
          ),
        ],
      ),
    );
  }
}
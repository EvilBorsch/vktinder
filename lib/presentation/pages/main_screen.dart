import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vktinder/presentation/controllers/nav_controller.dart';
import 'package:vktinder/presentation/pages/home_page.dart';
import 'package:vktinder/presentation/pages/settings_page.dart';

class MainScreen extends GetView<NavController> {
  const MainScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() => IndexedStack(
            index: controller.selectedIndex.value,
            children: const [
              HomePage(),
              SettingsPage(),
            ],
          )),
      bottomNavigationBar: Obx(() => BottomNavigationBar(
            currentIndex: controller.selectedIndex.value,
            onTap: controller.changePage,
            elevation: 8,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined, size: 28),
                activeIcon: Icon(Icons.home, size: 28),
                label: 'Главная',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined, size: 28),
                activeIcon: Icon(Icons.settings, size: 28),
                label: 'Настройки',
              ),
            ],
          )),
    );
  }
}

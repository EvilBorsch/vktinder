import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:vktinder/core/di/service_locator.dart';
import 'package:vktinder/core/theme/theme_service.dart';
import 'package:vktinder/routes/app_pages.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize GetStorage for persistent storage
  await GetStorage.init();

  // Initialize service locator
  ServiceLocator.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Get ThemeService from service locator
    final themeService = Get.find<ThemeService>();

    return GetMaterialApp(
      title: 'VK Tinder',
      debugShowCheckedModeBanner: false,
      defaultTransition: Transition.fade,
      themeMode: themeService.themeMode,
      theme: ThemeService.lightTheme,
      darkTheme: ThemeService.darkTheme,
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
    );
  }
}

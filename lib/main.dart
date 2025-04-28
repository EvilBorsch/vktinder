import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:vktinder/core/di/service_locator.dart';
import 'package:vktinder/core/theme/theme_service.dart';
import 'package:vktinder/data/providers/hive_storage_provider.dart';
import 'package:vktinder/routes/app_pages.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize GetStorage for persistent storage
  await GetStorage.init();

  // Initialize Hive for database storage
  await HiveStorageProvider.init();

  // Initialize Hive provider as a service and make sure it's registered
  final hiveProvider = await HiveStorageProvider.initService();

  // Ensure HiveStorageProvider is registered before initializing service locator
  if (!Get.isRegistered<HiveStorageProvider>()) {
    Get.put(hiveProvider, permanent: true);
  }

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

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vktinder/domain/usecases/group_users_usecase.dart';
import 'package:vktinder/presentation/controllers/home_controller.dart';
import 'package:vktinder/presentation/controllers/nav_controller.dart';
import 'package:vktinder/presentation/controllers/settings_controller.dart';
import 'package:vktinder/routes/app_pages.dart';
import 'package:vktinder/utils/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize core services
  final themeService = await ThemeService().init();
  Get.put(themeService, permanent: true);

  final groupUsersUsecase = await GroupUsersUsecase().init();
  Get.put(groupUsersUsecase, permanent: true);

  // Initialize SettingsController
  final settingsController = await SettingsController().init();
  Get.put(settingsController, permanent: true);

  Get.put(NavController());
  Get.put(HomeController());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'VK tinder',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeService.to.themeMode,
      theme: ThemeService.lightTheme,
      darkTheme: ThemeService.darkTheme,
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
    );
  }
}

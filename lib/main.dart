import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vktinder/domain/usecases/group_users_usecase.dart';
import 'package:vktinder/presentation/controllers/settings_controller.dart';
import 'package:vktinder/routes/app_pages.dart';
import 'package:vktinder/utils/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services and controllers
  await Get.putAsync(() => ThemeService().init());
  await Get.putAsync(() => GroupUsersUsecase().init());
  await Get.putAsync(() => SettingsController().init());

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

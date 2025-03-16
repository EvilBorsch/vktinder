import 'package:get/get.dart';
import 'package:vktinder/presentation/controllers/home_controller.dart';
import 'package:vktinder/presentation/controllers/nav_controller.dart';
import 'package:vktinder/presentation/controllers/settings_controller.dart';

class MainBinding extends Bindings {
  @override
  void dependencies() {
    // Register all controllers needed for the main screen
    Get.put(NavController());

    // Make sure SettingsController is registered
    if (!Get.isRegistered<SettingsController>()) {
      Get.put(SettingsController());
    }

    // Register HomeController
    Get.put(HomeController());
  }
}
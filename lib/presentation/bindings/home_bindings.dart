import 'package:get/get.dart';
import 'package:vktinder/presentation/controllers/home_controller.dart';
import 'package:vktinder/presentation/controllers/settings_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // Make sure SettingsController is registered first
    if (!Get.isRegistered<SettingsController>()) {
      Get.put(SettingsController());
    }

    // Then register HomeController
    Get.put(HomeController());
  }
}
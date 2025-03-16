import 'package:get/get.dart';
import 'package:vktinder/presentation/controllers/settings_controller.dart';

class SettingsBinding extends Bindings {
  @override
  void dependencies() {
    // Use find if it's already registered, otherwise register it
    if (!Get.isRegistered<SettingsController>()) {
      Get.put(SettingsController());
    }
  }
}
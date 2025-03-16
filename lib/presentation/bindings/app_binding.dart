import 'package:get/get.dart';
import 'package:vktinder/core/theme/theme_service.dart';
import 'package:vktinder/data/providers/local_storage_provider.dart';
import 'package:vktinder/data/providers/vk_api_provider.dart';
import 'package:vktinder/data/repositories/group_users_repository_impl.dart';
import 'package:vktinder/data/repositories/settings_repository_impl.dart';
import 'package:vktinder/presentation/controllers/home_controller.dart';
import 'package:vktinder/presentation/controllers/nav_controller.dart';
import 'package:vktinder/presentation/controllers/settings_controller.dart';


class AppBinding extends Bindings {
  @override
  void dependencies() {
    // Core
    Get.put(ThemeService(), permanent: true);

    // Providers
    Get.put(LocalStorageProvider(), permanent: true);
    Get.put(VkApiProvider());

    // Repositories
    Get.put<GroupUsersRepository>(
      GroupUsersRepository(),
    );
    Get.put<SettingsRepository>(
      SettingsRepository(), permanent: true,
    );

    // Controllers
    Get.put(NavController(), permanent: true);

    Get.lazyPut(() => SettingsController());
    Get.lazyPut(() => HomeController());
  }
}

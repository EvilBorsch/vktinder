import 'package:get/get.dart';
import 'package:vktinder/data/repositories/statistics_repository.dart';
import 'package:vktinder/presentation/controllers/statistics_controller.dart';
import 'package:vktinder/presentation/pages/full_user_info.dart';
import 'package:vktinder/presentation/pages/main_screen.dart';

import 'package:vktinder/core/theme/theme_service.dart';
import 'package:vktinder/data/providers/local_storage_provider.dart';
import 'package:vktinder/data/providers/vk_api_provider.dart';
import 'package:vktinder/data/repositories/group_users_repository_impl.dart';
import 'package:vktinder/data/repositories/settings_repository_impl.dart';
import 'package:vktinder/presentation/controllers/home_controller.dart';
import 'package:vktinder/presentation/controllers/nav_controller.dart';
import 'package:vktinder/presentation/controllers/settings_controller.dart';
import 'package:vktinder/presentation/controllers/user_detail_controller.dart';

abstract class Routes {
  static const MAIN = '/main';
  static const UserDetails = '/user_detail';
}


class AppBinding extends Bindings {
  @override
  void dependencies() {
    // Core services - permanent singletons
    Get.put(ThemeService(), permanent: true);
    Get.put(LocalStorageProvider(), permanent: true);
    Get.put(VkApiProvider(), permanent: true);

    // Repositories - permanent singletons
    Get.put<SettingsRepository>(SettingsRepository(), permanent: true);
    Get.put<GroupUsersRepository>(GroupUsersRepository(), permanent: true);
    Get.put<StatisticsRepository>(StatisticsRepository(), permanent: true);

    // Controllers for main navigation - permanent
    Get.put(NavController(), permanent: true);
    Get.put(StatisticsController(), permanent: true);
    Get.put(SettingsController(), permanent: true);
    Get.put(HomeController(), permanent: true);


    // Page-specific controller - recreated for each visit
    // Using fenix: true means it will be recreated if needed
    Get.lazyPut(() => UserDetailsController(), fenix: true);
  }
}
class AppPages {
  static const INITIAL = Routes.MAIN;

  static final routes = [
    GetPage(
      name: Routes.MAIN,
      page: () => const MainScreen(),
      binding: AppBinding(),
    ),
    GetPage(
      name: Routes.UserDetails,
      page: () => const UserDetailsPage(),
      binding: AppBinding(),
    ),
  ];
}

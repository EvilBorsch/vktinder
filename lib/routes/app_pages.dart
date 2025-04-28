import 'package:get/get.dart';
import 'package:vktinder/core/di/service_locator.dart';
import 'package:vktinder/presentation/pages/full_user_info.dart';
import 'package:vktinder/presentation/pages/main_screen.dart';

/// Routes for the app
abstract class Routes {
  static const MAIN = '/main';
  static const UserDetails = '/user_detail';
}

/// Binding that ensures dependencies are initialized
class AppBinding extends Bindings {
  @override
  void dependencies() {
    // Ensure all dependencies are initialized
    ServiceLocator.init();
  }
}

/// App pages configuration
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

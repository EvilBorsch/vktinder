import 'package:get/get.dart';
import 'package:vktinder/presentation/bindings/app_binding.dart';
import 'package:vktinder/presentation/pages/full_user_info.dart';
import 'package:vktinder/presentation/pages/main_screen.dart';

abstract class Routes {
  static const MAIN = '/main';
  static const UserDetails = '/user_detail';
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
      binding: DetailsBindings(),
    ),
  ];
}

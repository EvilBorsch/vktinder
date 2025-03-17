import 'package:get/get.dart';
import 'package:vktinder/presentation/bindings/app_binding.dart';
import 'package:vktinder/presentation/pages/main_screen.dart';

abstract class Routes {
  static const MAIN = '/main';
}

class AppPages {
  static const INITIAL = Routes.MAIN;

  static final routes = [
    GetPage(
      name: Routes.MAIN,
      page: () => const MainScreen(),
      binding: AppBinding(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),
  ];
}

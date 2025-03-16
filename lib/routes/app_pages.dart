import 'package:get/get.dart';
import 'package:vktinder/presentation/bindings/main_binding.dart';
import 'package:vktinder/presentation/pages/main_screen.dart';

// Define routes as constants
abstract class Routes {
  static const MAIN = '/main';
}

class AppPages {
  static const initial = Routes.MAIN;

  static final routes = [
    GetPage(
      name: Routes.MAIN,
      page: () => const MainScreen(),
      binding: MainBinding(),
    ),
  ];
}

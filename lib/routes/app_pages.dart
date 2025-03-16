import 'package:get/get.dart';
import 'package:vktinder/presentation/controllers/home_controller.dart';
import 'package:vktinder/presentation/pages/home_page.dart';
import 'package:vktinder/presentation/pages/settings_page.dart';

// Define routes as constants
abstract class Routes {
  static const HOME = '/home';
  static const SETTINGS = '/settings';
}

class AppPages {
  static const initial = Routes.HOME;

  static final routes = [    GetPage(      name: Routes.HOME,      page: () => HomePage(),      binding: BindingsBuilder(() {        Get.lazyPut(() => HomeController());      }),    ),    GetPage(      name: Routes.SETTINGS,      page: () => SettingsPage(),    ),  ];
}
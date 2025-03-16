import 'package:get/get.dart';
import 'package:vktinder/core/theme/theme_service.dart';
import 'package:vktinder/data/providers/local_storage_provider.dart';
import 'package:vktinder/data/providers/vk_api_provider.dart';
import 'package:vktinder/data/repositories/group_users_repository_impl.dart';
import 'package:vktinder/data/repositories/settings_repository_impl.dart';
import 'package:vktinder/domain/repositories/group_users_repository.dart';
import 'package:vktinder/domain/repositories/settings_repository.dart';
import 'package:vktinder/domain/usecases/group_users_usecase.dart';
import 'package:vktinder/domain/usecases/settings_usecase.dart';
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
    Get.put(VkApiProvider(), permanent: true);

    // Repositories
    Get.put<GroupUsersRepository>(
      GroupUsersRepositoryImpl(),
      permanent: true,
    );
    Get.put<SettingsRepository>(
      SettingsRepositoryImpl(),
      permanent: true,
    );

    // Use cases
    Get.put(GroupUsersUsecase(), permanent: true);
    Get.put(SettingsUsecase(), permanent: true);

    // Controllers
    Get.put(NavController(), permanent: true);
    Get.lazyPut(() => HomeController());
    Get.lazyPut(() => SettingsController());
  }
}

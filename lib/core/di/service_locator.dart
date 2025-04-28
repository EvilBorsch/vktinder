import 'package:get/get.dart';
import 'package:vktinder/core/theme/theme_service.dart';
import 'package:vktinder/data/providers/local_storage_provider.dart';
import 'package:vktinder/data/providers/vk_api_provider.dart';
import 'package:vktinder/data/repositories/group_users_repository_impl.dart';
import 'package:vktinder/data/repositories/settings_repository_impl.dart';
import 'package:vktinder/data/repositories/statistics_repository.dart';
import 'package:vktinder/data/services/data_transfer_service.dart';
import 'package:vktinder/presentation/controllers/home_controller.dart';
import 'package:vktinder/presentation/controllers/nav_controller.dart';
import 'package:vktinder/presentation/controllers/settings_controller.dart';
import 'package:vktinder/presentation/controllers/statistics_controller.dart';
import 'package:vktinder/presentation/controllers/user_detail_controller.dart';

/// Service locator for dependency injection
class ServiceLocator {
  /// Initialize all dependencies
  static void init() {
    // Register core services
    _registerCoreServices();

    // Register providers
    _registerProviders();

    // Register repositories
    _registerRepositories();

    // Register services
    _registerServices();

    // Register controllers
    _registerControllers();
  }

  /// Register core services
  static void _registerCoreServices() {
    Get.put(ThemeService(), permanent: true);
  }

  /// Register data providers
  static void _registerProviders() {
    // HiveStorageProvider is already registered in main.dart via HiveStorageProvider.initService()
    Get.put(LocalStorageProvider(), permanent: true);
    Get.put(VkApiProvider(), permanent: true);
  }

  /// Register repositories
  static void _registerRepositories() {
    Get.put<SettingsRepository>(SettingsRepository(), permanent: true);
    Get.put<GroupUsersRepository>(GroupUsersRepository(), permanent: true);
    Get.put<StatisticsRepository>(StatisticsRepository(), permanent: true);
  }

  /// Register services
  static void _registerServices() {
    Get.put(DataTransferService(), permanent: true);
  }

  /// Register controllers
  static void _registerControllers() {
    // Main controllers (permanent)
    Get.put(NavController(), permanent: true);
    Get.put(StatisticsController(), permanent: true);
    Get.put(SettingsController(), permanent: true);
    Get.put(HomeController(), permanent: true);

    // Page-specific controllers (lazy loaded)
    Get.lazyPut(() => UserDetailsController(), fenix: true);
  }

  /// Reset all dependencies (useful for testing)
  static void reset() {
    Get.reset();
    init();
  }
}

import 'package:get/get.dart';
import 'package:vktinder/domain/usecases/settings_usecase.dart';

class SettingsController extends GetxController {
  final SettingsUsecase _settingsUsecase = Get.find<SettingsUsecase>();

  // Observable settings
  final RxString _vkToken = ''.obs;
  final RxString _defaultMessage = ''.obs;
  final RxString _theme = 'system'.obs;

  // Observable to trigger reload after token change
  final RxInt tokenChange = 0.obs;

  // Getters for settings
  String get vkToken => _vkToken.value;
  String get defaultMessage => _defaultMessage.value;
  String get theme => _theme.value;

  @override
  void onInit() {
    super.onInit();
    loadSettings();
  }

  Future<void> loadSettings() async {
    final settings = await _settingsUsecase.getSettings();

    _vkToken.value = settings['vkToken'] ?? '';
    _defaultMessage.value = settings['defaultMessage'] ?? '';
    _theme.value = settings['theme'] ?? 'system';
  }

  Future<void> saveSettings({
    required String vkToken,
    required String defaultMessage,
    required String theme,
  }) async {
    // First update our reactive variables
    final bool tokenChanged = _vkToken.value != vkToken;

    _vkToken.value = vkToken;
    _defaultMessage.value = defaultMessage;
    _theme.value = theme;

    // Save to repository
    await _settingsUsecase.saveSettings(
      vkToken: vkToken,
      defaultMessage: defaultMessage,
      theme: theme,
    );

    // Trigger reload if token changed
    if (tokenChanged) {
      tokenChange.value++;
    }

    Get.snackbar(
      'Success',
      'Settings saved successfully',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }
}

import 'package:get/get.dart';
import 'package:vktinder/data/models/vk_group_user.dart';
import 'package:vktinder/presentation/controllers/settings_controller.dart';
import 'package:vktinder/data/repositories/group_users_repository_impl.dart';

class UserDetailsController extends GetxController {
  final Rx<VKGroupUser?> user = Rx<VKGroupUser?>(null);
  final RxBool isLoading = true.obs;

  final SettingsController _settingsController = Get.find<SettingsController>();
  final GroupUsersRepository _groupUsersRepository =
      Get.find<GroupUsersRepository>();

  @override
  void onInit() {
    super.onInit();
    final targetUser = Get.arguments as VKGroupUser;
    loadFullProfile(targetUser.userID);
  }

  Future<void> loadFullProfile(String userID) async {
    try {
      isLoading.value = true;
      final userDetails = await _groupUsersRepository.getFullProfile(
        _settingsController.vkToken,
        userID,
      );
      user.value = userDetails;
    } catch (e) {
      // Handle error
    } finally {
      isLoading.value = false;
    }
  }
}

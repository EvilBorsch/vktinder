import 'package:get/get.dart';
import 'package:vktinder/data/models/vk_group_user.dart';
import 'package:vktinder/domain/repositories/group_users_repository.dart';

class GroupUsersUsecase extends GetxService {
  final GroupUsersRepository _repository = Get.find<GroupUsersRepository>();

  Future<List<VKGroupUser>> getUsers(String vkToken) async {
    return await _repository.getUsers(vkToken);
  }

  Future<List<VKGroupUser>> removeFirstUser(String vkToken, List<VKGroupUser> users) async {
    return await _repository.removeFirstUser(vkToken, users);
  }

  Future<bool> sendMessage(String vkToken, String userId, String message) async {
    return await _repository.sendMessage(vkToken, userId, message);
  }
}

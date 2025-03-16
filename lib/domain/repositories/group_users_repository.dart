import 'package:vktinder/data/models/vk_group_user.dart';

abstract class GroupUsersRepository {
  Future<List<VKGroupUser>> getUsers(String vkToken);
  Future<List<VKGroupUser>> removeFirstUser(String vkToken, List<VKGroupUser> users);
  Future<bool> sendMessage(String vkToken, String userId, String message);
}
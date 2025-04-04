import 'package:get/get.dart';
import 'package:vktinder/data/models/vk_group_user.dart';
import 'package:vktinder/data/providers/local_storage_provider.dart';
import 'package:vktinder/data/providers/vk_api_provider.dart';

class GroupUsersRepository {
  final LocalStorageProvider _storageProvider =
      Get.find<LocalStorageProvider>();
  final VkApiProvider _apiProvider = Get.find<VkApiProvider>();

  Future<List<VKGroupUser>> getUsers(String vkToken) async {
    // Try to load from cache first
    var cachedUsers = await _storageProvider.getStoredCards();

    // If cache is empty or token changed, fetch from network
    if (cachedUsers.length <= 1 && vkToken.isNotEmpty) {
      cachedUsers = await _apiProvider.getGroupUsers(vkToken);
      await _storageProvider.saveCards(cachedUsers);
    }

    return cachedUsers;
  }

  Future<VKGroupUser> getFullProfile(String vkToken, String userID) async {
    var profileInfo = await _apiProvider.getFullProfile(vkToken, userID);
    final photoInfo = await _apiProvider.getUserPhotos(vkToken, userID);
    profileInfo.photos = photoInfo;
    return profileInfo;
  }

  Future<List<VKGroupUser>> removeFirstUser(
      String vkToken, List<VKGroupUser> users) async {
    if (users.isEmpty) {
      return await getUsers(vkToken);
    }

    if (users.length == 1) {
      // When only one user left, fetch new batch
      return await getUsers(vkToken);
    }

    // Remove the first user
    final updatedUsers = [...users];
    updatedUsers.removeAt(0);

    // Save updated list to cache
    await _storageProvider.saveCards(updatedUsers);

    return updatedUsers;
  }

  Future<bool> sendMessage(
      String vkToken, String userId, String message) async {
    return await _apiProvider.sendMessage(vkToken, userId, message);
  }
}

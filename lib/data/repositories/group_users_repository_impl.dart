// lib/data/repositories/group_users_repository_impl.dart
import 'package:get/get.dart';
import 'package:vktinder/data/models/vk_group_user.dart';
import 'package:vktinder/data/models/vk_group_info.dart'; // Import VKGroupInfo
import 'package:vktinder/data/providers/local_storage_provider.dart';
import 'package:vktinder/data/providers/vk_api_provider.dart';
// Potentially import SettingsController if groupId comes from there
// import 'package:vktinder/presentation/controllers/settings_controller.dart';

class GroupUsersRepository {
  final LocalStorageProvider _storageProvider = Get.find<LocalStorageProvider>();
  final VkApiProvider _apiProvider = Get.find<VkApiProvider>();
  // Example: Assuming groupId is somehow configured or static for now
  // In a real app, this should come from settings or a dynamic source
  final String _targetGroupId = "25504844"; // <<< --- !!! SET YOUR TARGET GROUP ID HERE !!!

  // getUsers (remains the same)
  Future<List<VKGroupUser>> getUsers(String vkToken) async {
    // ... existing code ...
    // Try to load from cache first
    var cachedUsers = await _storageProvider.getStoredCards();

    // If cache has few users left (e.g., <=1) OR token changed, fetch from network
    // Always check if token and groupId are valid before making API call
    if (cachedUsers.length <= 1 && vkToken.isNotEmpty && _targetGroupId.isNotEmpty) {
      try {
        print("Fetching users from VK API for group: $_targetGroupId");
        // Pass the required groupId
        final fetchedUsers = await _apiProvider.getGroupUsers(vkToken, _targetGroupId);
        // Filter out users already seen (if necessary, depends on product reqs)
        // For simplicity, we just replace the cache now
        cachedUsers = fetchedUsers;

        if (cachedUsers.isNotEmpty) {
          await _storageProvider.saveCards(cachedUsers);
        } else {
          // Clear cache if API returns empty to avoid showing stale users
          await _storageProvider.saveCards([]);
        }
      } catch (e) {
        print("Error in repository getUsers: $e");
        // Return empty list on API error to prevent showing old data after failure
        return [];
      }
    } else if (vkToken.isEmpty || _targetGroupId.isEmpty) {
      print("VK Token or Group ID missing, cannot fetch new users.");
      // Clear cache if token is invalid or missing
      await _storageProvider.saveCards([]);
      return [];
    }


    return cachedUsers;
  }


  // MODIFIED getFullProfile
  Future<VKGroupUser> getFullProfile(String vkToken, String userID) async {
    List<String> photos = [];
    List<VKGroupInfo> groups = [];

    // Fetch base profile info first
    // This can throw, let the controller handle it
    final baseProfileInfo = await _apiProvider.getFullProfile(vkToken, userID);

    // Fetch photos and groups concurrently (if possible and desired)
    // Or sequentially with error handling for each part
    try {
      photos = await _apiProvider.getUserPhotos(vkToken, userID);
    } catch (e) {
      print("Error fetching photos for profile $userID: $e");
      // Continue without photos, assign empty list
      photos = [];
    }

    try {
      // First get subscription IDs
      final groupIdsInt = await _apiProvider.getUserSubscriptionIds(vkToken, userID);
      if (groupIdsInt.isNotEmpty) {
        // Convert IDs to strings for the next API call
        final groupIdsStr = groupIdsInt.map((id) => id.toString()).toList();
        // Fetch detailed group info
        groups = await _apiProvider.getGroupsById(vkToken, groupIdsStr);
      } else {
        print("No group subscription IDs found or accessible for user $userID.");
        groups = [];
      }
    } catch (e) {
      print("Error fetching or processing groups for profile $userID: $e");
      // Continue without groups, assign empty list
      groups = [];
    }

    // Return a new VKGroupUser instance containing all fetched data
    // Create a new instance instead of modifying the one from _apiProvider.getFullProfile
    // if VKGroupUser's fields (like photos, groups) are final.
    return VKGroupUser(
      userID: baseProfileInfo.userID,
      name: baseProfileInfo.name,
      surname: baseProfileInfo.surname,
      avatar: baseProfileInfo.avatar,
      interests: baseProfileInfo.interests,
      about: baseProfileInfo.about,
      status: baseProfileInfo.status,
      bdate: baseProfileInfo.bdate,
      city: baseProfileInfo.city,
      country: baseProfileInfo.country,
      sex: baseProfileInfo.sex,
      relation: baseProfileInfo.relation,
      screenName: baseProfileInfo.screenName,
      online: baseProfileInfo.online,
      lastSeen: baseProfileInfo.lastSeen,
      photos: photos, // Assign fetched photos
      groups: groups,  // Assign fetched groups
    );
  }


  Future<List<VKGroupUser>> removeFirstUser(
      String vkToken, List<VKGroupUser> users) async {
    // ... existing code ...
    if (users.isEmpty) {
      return await getUsers(vkToken);
    }

    final updatedUsers = List<VKGroupUser>.from(users);
    updatedUsers.removeAt(0);

    await _storageProvider.saveCards(updatedUsers);

    if (updatedUsers.length <= 1) {
      print("User list short after removal, will fetch on next card request.");
      // Consider triggering background fetch here:
      // Future.microtask(() => getUsers(vkToken)); // Fire-and-forget background fetch
    }

    return updatedUsers;
  }

  Future<bool> sendMessage(
      String vkToken, String userId, String message) async {
    return await _apiProvider.sendMessage(vkToken, userId, message);
  }
}


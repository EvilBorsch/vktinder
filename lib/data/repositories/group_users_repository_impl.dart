import 'package:get/get.dart';
import 'package:vktinder/data/models/vk_group_user.dart';
import 'package:vktinder/data/providers/local_storage_provider.dart';
import 'package:vktinder/data/providers/vk_api_provider.dart';
// Potentially import SettingsController if groupId comes from there
// import 'package:vktinder/presentation/controllers/settings_controller.dart';

class GroupUsersRepository {
  final LocalStorageProvider _storageProvider =
  Get.find<LocalStorageProvider>();
  final VkApiProvider _apiProvider = Get.find<VkApiProvider>();
  // Example: Assuming groupId is somehow configured or static for now
  // In a real app, this should come from settings or a dynamic source
  final String _targetGroupId = "25504844"; // <<< --- !!! SET YOUR TARGET GROUP ID HERE !!!


  // Modified signature potentially needed if groupId is passed dynamically
  // Future<List<VKGroupUser>> getUsers(String vkToken, String groupId) async {
  Future<List<VKGroupUser>> getUsers(String vkToken) async {
    // Try to load from cache first
    var cachedUsers = await _storageProvider.getStoredCards();

    // If cache has few users left (e.g., <=1) OR token changed, fetch from network
    // Always check if token and groupId are valid before making API call
    if (cachedUsers.length <= 1 && vkToken.isNotEmpty && _targetGroupId.isNotEmpty) {
      try {
        print("Fetching users from VK API for group: $_targetGroupId");
        // Pass the required groupId
        cachedUsers = await _apiProvider.getGroupUsers(vkToken, _targetGroupId);
        // Only save if we got new users
        if (cachedUsers.isNotEmpty) {
          await _storageProvider.saveCards(cachedUsers);
        } else {
          // If API returns empty, clear cache to avoid showing stale users next time?
          // Or keep the last one? Depends on desired behavior.
          // For now, clear it if the API fetch was attempted but failed to return users.
          await _storageProvider.saveCards([]); // Clear cache on empty API result
        }
      } catch (e) {
        print("Error in repository getUsers: $e");
        // Optionally show a user-facing error via Get.snackbar or similar
        // Decide if you want to return the (potentially outdated) cached users or empty
        // Returning empty indicates a definite failure to load new ones.
        return []; // Return empty list on API error
      }
    } else if (vkToken.isEmpty || _targetGroupId.isEmpty) {
      print("VK Token or Group ID missing, cannot fetch new users.");
      // Maybe clear cache if token is invalid?
      await _storageProvider.saveCards([]);
      return [];
    }


    return cachedUsers;
  }

  Future<VKGroupUser> getFullProfile(String vkToken, String userID) async {
    // Fetch base profile info
    var profileInfo = await _apiProvider.getFullProfile(vkToken, userID);

    // Fetch photos separately
    try {
      final photoInfo = await _apiProvider.getUserPhotos(vkToken, userID);
      profileInfo.photos = photoInfo; // Assign photos to the model instance
    } catch (e) {
      print("Error fetching photos for profile: $e");
      // Decide how to handle photo fetch failure: continue without photos?
      profileInfo.photos = []; // Assign empty list on error
    }

    // Potentially fetch group names here if needed, based on group IDs returned in users.get
    // This would require another API call like groups.getById

    return profileInfo; // Return the enriched profile
  }


  Future<List<VKGroupUser>> removeFirstUser(
      String vkToken, List<VKGroupUser> users) async {
    if (users.isEmpty) {
      // If list is already empty, try fetching a new batch
      return await getUsers(vkToken);
    }

    // Remove the first user from the current list
    final updatedUsers = List<VKGroupUser>.from(users); // Create mutable copy
    updatedUsers.removeAt(0);

    // Save updated (shorter) list to cache immediately
    await _storageProvider.saveCards(updatedUsers);

    // If the list becomes very short after removal, fetch a new batch in the background?
    // Or rely on the check in getUsers() next time it's called.
    // For simplicity, we'll just return the updated list. The next call to
    // getUsers (likely triggered by HomeController needing more cards) will fetch.
    if (updatedUsers.length <= 1) {
      print("User list short after removal, will fetch on next card request.");
      // Optionally trigger a background fetch here if desired
    }

    return updatedUsers;
  }

  Future<bool> sendMessage(
      String vkToken, String userId, String message) async {
    // Delegate directly to the provider
    return await _apiProvider.sendMessage(vkToken, userId, message);
  }
}

// lib/data/repositories/group_users_repository_impl.dart
import 'dart:async';

import 'package:collection/collection.dart'; // For firstWhereOrNull
import 'package:get/get.dart';
import 'package:vktinder/data/models/vk_group_user.dart';
import 'package:vktinder/data/models/vk_group_info.dart';
import 'package:vktinder/data/providers/local_storage_provider.dart';
import 'package:vktinder/data/providers/vk_api_provider.dart';
import 'package:vktinder/data/repositories/settings_repository_impl.dart'; // Import SettingsRepository

class GroupUsersRepository {
  final LocalStorageProvider _storageProvider =
      Get.find<LocalStorageProvider>();
  final VkApiProvider _apiProvider = Get.find<VkApiProvider>();
  // Get SettingsRepository to access all settings easily
  final SettingsRepository _settingsRepository = Get.find<SettingsRepository>();

  // Get stored cards from local storage
  Future<List<VKGroupUser>> getStoredCards() async {
    return await _storageProvider.getStoredCards();
  }

  // Save cards to local storage
  Future<void> saveCards(List<VKGroupUser> cards) async {
    await _storageProvider.saveCards(cards);
  }

  // --- MODIFIED getUsers ---
  Future<List<VKGroupUser>> getUsers(String vkToken, List<String> skippedIDs) async {
    // 1. Get settings
    final cityNames = _settingsRepository.getCities();
    final (ageFrom, ageTo) = _settingsRepository.getAgeRange();
    final sexFilter = _settingsRepository.getSexFilter();
    final groupUrls = _settingsRepository.getGroupUrls();
    final skipClosedProfiles = _settingsRepository.getSkipClosedProfiles();

    // Check prerequisites
    if (vkToken.isEmpty) {
      print("VK Token missing, cannot fetch users.");
      // Don't clear storage here, let the controller handle it
      return [];
    }
    if (groupUrls.isEmpty) {
      print("No target groups configured in settings.");
      // Don't clear storage here, let the controller handle it
      return [];
    }

    // 2. Resolve City Names and Group URLs to IDs concurrently
    final Map<String, int> cityIdMap =
        await _resolveCityNames(vkToken, cityNames);
    final List<VKGroupInfo?> groupInfos =
        await _resolveGroupUrls(vkToken, groupUrls);

    final List<int> targetGroupIds = groupInfos
        .whereType<VKGroupInfo>()
        .map((g) => g.id)
        .where((id) => id > 0)
        .toSet()
        .toList(); // Unique, valid IDs
    final List<int> targetCityIds =
        cityIdMap.values.toSet().toList(); // Unique, valid IDs

    if (targetGroupIds.isEmpty) {
      print("Could not resolve any valid group IDs from the provided URLs.");
      // Optionally show a message to the user via controller/snackbar
      // Don't clear storage here, let the controller handle it
      return [];
    }

    print(
        "Search Params: Groups=${targetGroupIds.join(',')}, Cities=${targetCityIds.join(',')}, Age=$ageFrom-$ageTo, SkipClosed=$skipClosedProfiles");

    // 3. Perform Search using users.search
    // We need to iterate through groups and potentially cities if the API requires it.
    // users.search *can* take a single group_id and a single city_id.
    // If multiple cities are selected, we might need multiple searches.
    // If multiple groups are selected, we *definitely* need multiple searches.

    final Set<VKGroupUser> foundUsers =
        {}; // Use a Set to automatically handle duplicates
    final Set<String> closedProfileIds =
        {}; // Track closed profile IDs for logging
    const int searchLimitPerRequest =
        100; // VK limit is 1000, but smaller batches might be safer/faster start
    bool reachedVkLimit = false; // Flag if VK stops returning results

    // Prioritize searching within specified cities if any are given
    final searchCityIds = targetCityIds.isNotEmpty
        ? targetCityIds
        : [null]; // Use null if no cities specified

    for (final groupId in targetGroupIds) {
      for (final cityId in searchCityIds) {
        int currentOffset = 0;
        int totalFoundInCombo =
            0; // Track total for this specific group/city combo
        const maxOffset =
            900; // VK search offset limit seems to be around 1000 total results

        while (currentOffset <= maxOffset && !reachedVkLimit) {
          try {
            final List<VKGroupUser> batch = await _apiProvider.searchUsers(
              vkToken: vkToken,
              groupId: groupId,
              cityId: cityId, // Can be null
              ageFrom: ageFrom,
              ageTo: ageTo,
              sex: sexFilter, // Use the sex filter from settings
              count: searchLimitPerRequest,
              offset: currentOffset,
            );

            if (batch.isEmpty) {
              // If we get an empty batch, assume we've got all users for this combo or hit a VK limit
              if (currentOffset > 0) {
                print(
                    "Finished searching group $groupId / city ${cityId ?? 'any'} at offset $currentOffset.");
              } else {
                print(
                    "No users found for group $groupId / city ${cityId ?? 'any'} with current filters.");
              }
              break; // Move to the next city/group combination
            }

            // Filter out users already found (Set handles this) and add new ones
            int addedCount = 0;
            int closedCount = 0;
            for (var user in batch) {
              // Check if we should skip closed profiles
              bool isClosed =
                  await _isProfileClosed(vkToken, user.userID, user: user);
              if (isClosed) {
                closedProfileIds.add(user.userID);
                closedCount++;
                if (skipClosedProfiles) {
                  continue; // Skip this user
                }
              }
              if (skippedIDs.contains(user.userID)){
                print("skipping ${user.userID} because its already swiped");
                continue;
              }

              if (foundUsers.add(user)) {
                // add returns true if element was not already in the set
                addedCount++;
              }
            }
            print(
                "Added $addedCount new users from group $groupId / city ${cityId ?? 'any'} (offset: $currentOffset). Skipped $closedCount closed profiles. Total unique: ${foundUsers.length}");

            totalFoundInCombo +=
                batch.length; // Increment total for this specific combo
            currentOffset += searchLimitPerRequest; // Prepare for the next page

            // Optional: Add a small delay between paginated requests
            if (batch.length == searchLimitPerRequest) {
              // Only delay if we likely hit the count limit
              await Future.delayed(const Duration(milliseconds: 350));
            }
          } catch (e) {
            print(
                "Error during users.search (group $groupId, city ${cityId ?? 'any'}, offset $currentOffset): $e");
            // Decide whether to stop all searches or just skip this combo/group
            // For now, let's break this inner loop and try the next combo
            reachedVkLimit =
                true; // Assume a potentially blocking error (like rate limit/auth)
            break; // Stop searching this city/group combo on error
          }
        } // End while loop (pagination)
        if (reachedVkLimit)
          break; // Stop searching cities if a major error occurred
      } // End city loop
      if (reachedVkLimit)
        break; // Stop searching groups if a major error occurred
    } // End group loop

    // 4. Convert Set to List and Return
    final usersList = foundUsers.toList();
    print(
        "Total unique users found across all groups/cities: ${usersList.length}");

    // We no longer clear storage here - the HomeController will handle
    // saving the combined list of existing and new cards

    return usersList;
  }

  // Helper to resolve city names
  Future<Map<String, int>> _resolveCityNames(
      String vkToken, List<String> cityNames) async {
    if (cityNames.isEmpty) return {};
    try {
      return await _apiProvider.getCityIdsByNames(vkToken, cityNames);
    } catch (e) {
      print("Error resolving city names: $e");
      return {}; // Return empty on error
    }
  }

  // Helper to resolve group URLs/screen names
  Future<List<VKGroupInfo?>> _resolveGroupUrls(
      String vkToken, List<String> groupUrls) async {
    List<Future<VKGroupInfo?>> futures = [];
    for (final url in groupUrls) {
      futures.add(_apiProvider.getGroupInfoByScreenName(vkToken, url));
      // Add delay between resolution requests if needed
      // await Future.delayed(const Duration(milliseconds: 100));
    }
    try {
      final results = await Future.wait(futures);
      // Filter out nulls (failed resolutions) and potentially log them
      final failedUrls = groupUrls
          .whereIndexed((index, url) => results[index] == null)
          .toList();
      if (failedUrls.isNotEmpty) {
        print(
            "Could not resolve the following group URLs/names: ${failedUrls.join(', ')}");
        // Consider notifying the user via the controller
      }
      return results; // Keep nulls for now, filter later
    } catch (e) {
      print("Error resolving group URLs: $e");
      return List.filled(
          groupUrls.length, null); // Return list of nulls on major error
    }
  }

  Future<VKGroupUser> getFullProfile(String vkToken, String userID) async {
    List<String> photos = [];
    List<VKGroupInfo> groups = [];

    // Fetch base profile info first
    final baseProfileInfo = await _apiProvider.getFullProfile(vkToken, userID);

    // Fetch photos and groups concurrently
    try {
      final results = await Future.wait([
        _apiProvider.getUserPhotos(vkToken, userID),
        _fetchUserGroups(vkToken, userID), // Use helper for group fetching
      ]);
      photos = results[0] as List<String>;
      groups = results[1] as List<VKGroupInfo>;
    } catch (e) {
      print("Error fetching photos or groups concurrently for profile $userID: $e");
      // Try fetching sequentially if concurrent fails (optional, adds complexity)
      try {
        photos = await _apiProvider.getUserPhotos(vkToken, userID);
      } catch (e) {
        print("Sequential photo fetch failed: $e");
        photos = [];
      }
      try {
        groups = await _fetchUserGroups(vkToken, userID);
      } catch (e) {
        print("Sequential group fetch failed: $e");
        groups = [];
      }
    }

    // Create a new instance with all the data, making sure to properly pass the status and relation
    final result = VKGroupUser(
      userID: baseProfileInfo.userID,
      name: baseProfileInfo.name,
      surname: baseProfileInfo.surname,
      avatar: baseProfileInfo.avatar,
      interests: baseProfileInfo.interests,
      about: baseProfileInfo.about,
      status: baseProfileInfo.status, // Make sure this is passed correctly
      bdate: baseProfileInfo.bdate,
      city: baseProfileInfo.city,
      country: baseProfileInfo.country,
      sex: baseProfileInfo.sex,
      relation: baseProfileInfo.relation, // Make sure this is passed correctly
      screenName: baseProfileInfo.screenName,
      online: baseProfileInfo.online,
      lastSeen: baseProfileInfo.lastSeen,
      photos: photos,
      groups: groups.isNotEmpty ? groups : [],
      canWritePrivateMessage: baseProfileInfo.canWritePrivateMessage,
    );

    return result;
  }


  // Helper function to fetch group info for a user
  Future<List<VKGroupInfo>> _fetchUserGroups(
      String vkToken, String userID) async {
    try {
      final groupIdsInt =
          await _apiProvider.getUserSubscriptionIds(vkToken, userID);
      if (groupIdsInt.isNotEmpty) {
        final groupIdsStr = groupIdsInt.map((id) => id.toString()).toList();
        // Fetch detailed group info
        return await _apiProvider.getGroupsById(vkToken, groupIdsStr);
      } else {
        print(
            "No group subscription IDs found or accessible for user $userID.");
        return [];
      }
    } catch (e) {
      print("Error fetching user groups for profile $userID: $e");
      return [];
    }
  }

  // This method is no longer needed as we handle card removal directly in HomeController
  // and save the updated list to storage there

  // Helper method to check if a profile is closed based on the canWritePrivateMessage field
  Future<bool> _isProfileClosed(String vkToken, String userId,
      {VKGroupUser? user}) async {
    // If we have the user object and it has the canWritePrivateMessage field,
    // we can use that to determine if the profile is closed
    if (user != null && user.canWritePrivateMessage != null) {
      // If canWritePrivateMessage is false, the profile is likely closed
      return !user.canWritePrivateMessage!;
    }

    // If we don't have the user object or it doesn't have the canWritePrivateMessage field,
    // we'll just return false to avoid making additional API calls
    return false;
  }

  // sendMessage (Remains the same)
  Future<bool> sendMessage(
      String vkToken, String userId, String message) async {
    return await _apiProvider.sendMessage(vkToken, userId, message);
  }
}

// --- File: lib/data/repositories/group_users_repository_impl.dart ---
// lib/data/repositories/group_users_repository_impl.dart
import 'dart:async';

import 'package:collection/collection.dart'; // For firstWhereOrNull
import 'package:get/get.dart';
import 'package:vktinder/data/models/vk_group_user.dart';
import 'package:vktinder/data/models/vk_group_info.dart';
import 'package:vktinder/data/providers/vk_api_provider.dart';
import 'package:vktinder/data/repositories/settings_repository_impl.dart'; // Import SettingsRepository

class GroupUsersRepository {
  final VkApiProvider _apiProvider = Get.find<VkApiProvider>();

  // Get SettingsRepository to access all settings easily
  final SettingsRepository _settingsRepository = Get.find<SettingsRepository>();



  // --- MODIFIED getUsers ---
  Future<List<VKGroupUser>> getUsers(
      String vkToken, List<String> skippedIDs) async {
    // 1. Get settings
    final cityNames = _settingsRepository.getCities();
    final (ageFrom, ageTo) = _settingsRepository.getAgeRange();
    final sexFilter = _settingsRepository.getSexFilter();
    final groupUrls = _settingsRepository.getGroupUrls();
    final skipClosedProfiles = _settingsRepository.getSkipClosedProfiles();
    final skipRelationFilter = _settingsRepository.getSkipRelationFilter(); // Get new setting

    // Check prerequisites
    if (vkToken.isEmpty) {
      print("VK Token missing, cannot fetch users.");
      return [];
    }
    if (groupUrls.isEmpty) {
      print("No target groups configured in settings.");
      return [];
    }

    // 2. Resolve City Names and Group URLs to IDs concurrently
    final Map<String, int> cityIdMap =
    await _resolveCityNames(vkToken, cityNames);
    final List<VKGroupInfo?> groupInfosNullable =
    await _resolveGroupUrls(vkToken, groupUrls);

    // Filter out groups that failed to resolve
    final List<VKGroupInfo> groupInfos = groupInfosNullable.whereType<VKGroupInfo>().toList();

    final Map<int, String> groupIdToUrlMap = { for (var g in groupInfos) g.id : g.sourceUrl! };
    final List<int> targetGroupIds = groupInfos.map((g) => g.id).toList();


    final List<int> targetCityIds =
    cityIdMap.values.toSet().toList(); // Unique, valid IDs

    if (targetGroupIds.isEmpty) {
      print("Could not resolve any valid group IDs from the provided URLs.");
      return [];
    }

    print(
        "Search Params: Groups=${targetGroupIds.join(',')}, Cities=${targetCityIds.join(',')}, Age=$ageFrom-$ageTo, Sex=$sexFilter, SkipClosed=$skipClosedProfiles, SkipRelation=$skipRelationFilter");

    // 3. Perform Search using users.search
    final Set<VKGroupUser> foundUsers =
    {}; // Use a Set to automatically handle duplicates
    final Set<String> profileAccessLimitedIds =
    {}; // Track profiles where can_see_all_posts is false
    final Set<String> relationFilteredIds =
    {}; // Track profiles filtered by relation
    const int searchLimitPerRequest =
    100; // VK limit is 1000, but smaller batches might be safer/faster start
    bool reachedVkLimit = false; // Flag if VK stops returning results

    // Prioritize searching within specified cities if any are given
    final searchCityIds = targetCityIds.isNotEmpty
        ? targetCityIds
        : [null]; // Use null if no cities specified

    for (final groupId in targetGroupIds) {
      // Get the original URL associated with this ID for context
      final String? groupURL = groupIdToUrlMap[groupId];

      if (groupURL == null) {
        print("Warning: Could not find original URL for group ID $groupId. Skipping.");
        continue; // Should not happen if map is built correctly
      }

      for (final cityId in searchCityIds) {
        int currentOffset = 0;
        int totalFoundInCombo = 0;
        const maxOffset = 900; // VK search offset limit

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
              groupURL: groupURL, // Pass the group URL
            );

            if (batch.isEmpty) {
              if (currentOffset > 0) {
                print("Finished searching group $groupId / city ${cityId ?? 'any'} at offset $currentOffset.");
              } else {
                print("No users found for group $groupId / city ${cityId ?? 'any'} with current filters.");
              }
              break;
            }

            int addedCount = 0;
            int skippedClosedCount = 0;
            int skippedRelationCount = 0;
            int skippedAlreadySeenCount = 0;

            for (var user in batch) {
              // Check if already swiped
              if (skippedIDs.contains(user.userID)) {
                skippedAlreadySeenCount++;
                // print("Skipping ${user.userID} because it was already swiped"); // Verbose logging
                continue;
              }

              // Check relation status filter
              if (skipRelationFilter && !(user.relation == 0 || user.relation == 6 || user.relation == 1)) {
                relationFilteredIds.add(user.userID);
                skippedRelationCount++;
                // print("Skipping relation filter: User ${user.userID}, relation: ${user.relation}"); // Verbose logging
                continue;
              }

              // Check profile access filter (using can_see_all_posts)
              bool isLimitedAccess = _isProfileAccessLimited(user);
              if (isLimitedAccess) {
                profileAccessLimitedIds.add(user.userID);
                if (skipClosedProfiles) {
                  skippedClosedCount++;
                  // print("Skipping closed/limited profile: User ${user.userID}"); // Verbose logging
                  continue; // Skip this user
                }
              }

              // Add user if not already present
              if (foundUsers.add(user)) {
                addedCount++;
              }
            }
            print(
                "Batch (Group $groupId/City ${cityId ?? 'any'}/Offset $currentOffset): Found ${batch.length}, Added $addedCount new. Skipped: $skippedAlreadySeenCount (seen), $skippedRelationCount (relation), $skippedClosedCount (closed). Total unique: ${foundUsers.length}");

            totalFoundInCombo += batch.length;
            currentOffset += searchLimitPerRequest;

            if (batch.length == searchLimitPerRequest) {
              await Future.delayed(const Duration(milliseconds: 350));
            }

          } catch (e) {
            print(
                "Error during users.search (group $groupId, city ${cityId ?? 'any'}, offset $currentOffset): $e");
            reachedVkLimit = true; // Assume a potentially blocking error
            break;
          }
        } // End while loop (pagination)
        if (reachedVkLimit) break; // Stop searching cities
      } // End city loop
      if (reachedVkLimit) break; // Stop searching groups
    } // End group loop

    // 4. Convert Set to List and Return
    final usersList = foundUsers.toList();
    print(
        "Total unique users found across all groups/cities: ${usersList.length}");
    print("Total profiles skipped due to relation filter: ${relationFilteredIds.length}");
    print("Total profiles skipped due to limited access filter: ${profileAccessLimitedIds.length}");



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
      // Short delay between API calls
      await Future.delayed(const Duration(milliseconds: 200));
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
        // Consider notifying the user via the controller/snackbar
      }
      return results; // Return list potentially containing nulls
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
      print(
          "Error fetching photos or groups concurrently for profile $userID: $e");
      // Non-critical, log and continue with potentially empty lists
    }

    // Create a new instance with all the data
    final result = VKGroupUser(
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
        canWritePrivateMessage: baseProfileInfo.canWritePrivateMessage,
        canSeeAllPosts: baseProfileInfo.canSeeAllPosts, // Include the field
        photos: photos,
        groups: groups, // Assign fetched groups
        groupURL: baseProfileInfo.groupURL // Preserve groupURL if it came from search
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
        // print("No group subscription IDs found or accessible for user $userID."); // Less noisy log
        return [];
      }
    } catch (e) {
      print("Error fetching user groups for profile $userID: $e");
      return [];
    }
  }

  // Helper method to check if a profile has limited access based on can_see_all_posts and canWritePrivateMessage
  bool _isProfileAccessLimited(VKGroupUser user) {
    return user.canSeeAllPosts == false || user.canWritePrivateMessage == false;
  }

  // sendMessage (Remains the same)
  Future<bool> sendMessage(
      String vkToken, String userId, String message) async {
    return await _apiProvider.sendMessage(vkToken, userId, message);
  }
}
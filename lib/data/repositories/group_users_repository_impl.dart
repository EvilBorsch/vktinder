// --- File: lib/data/repositories/group_users_repository_impl.dart ---
// lib/data/repositories/group_users_repository_impl.dart
import 'dart:async';
import 'dart:math';

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
    final Set<VKGroupUser> foundUsers = {}; // Use a Set to automatically handle duplicates
    final Set<String> profileAccessLimitedIds = {}; // Track profiles where is_closed is true
    final Set<String> relationFilteredIds = {}; // Track profiles filtered by relation
    const int searchLimitPerRequest = 1000; // Maximum allowed by VK API
    bool reachedVkLimit = false; // Flag if VK stops returning results

    // Prioritize searching within specified cities if any are given
    final searchCityIds = targetCityIds.isNotEmpty
        ? targetCityIds
        : [null]; // Use null if no cities specified

    final random = Random();

    for (final groupId in targetGroupIds) {
      // Get the original URL associated with this ID for context
      final String? groupURL = groupIdToUrlMap[groupId];

      if (groupURL == null) {
        print("Warning: Could not find original URL for group ID $groupId. Skipping.");
        continue; // Should not happen if map is built correctly
      }

      for (final cityId in searchCityIds) {
        if (reachedVkLimit) break; // Stop searching cities if hit limit
        
        try {
          // Add a delay before each API request (0.2 sec base + random 0.1-0.5 sec)
          // This respects VK's rate limit of max 3 RPS
          final randomDelay = 100 + random.nextInt(400); // 100-500ms random component
          await Future.delayed(Duration(milliseconds: 200 + randomDelay));
          
          print("Requesting users: Group $groupId / City ${cityId ?? 'any'}");
          
          // Single request with maximum count (1000)
          final List<VKGroupUser> users = await _apiProvider.searchUsers(
            vkToken: vkToken,
            groupId: groupId,
            cityId: cityId, // Can be null
            ageFrom: ageFrom,
            ageTo: ageTo,
            sex: sexFilter, // Use the sex filter from settings
            count: searchLimitPerRequest,
            offset: 0, // No pagination needed, VK returns max 1000
            groupURL: groupURL, // Pass the group URL
          );

          if (users.isEmpty) {
            print("No users found for group $groupId / city ${cityId ?? 'any'} with current filters.");
            continue;
          }

          int addedCount = 0;
          int skippedClosedCount = 0;
          int skippedRelationCount = 0;
          int skippedAlreadySeenCount = 0;

          for (var user in users) {
            // Check if already swiped
            if (skippedIDs.contains(user.userID)) {
              skippedAlreadySeenCount++;
              continue;
            }

            // Check relation status filter
            if (skipRelationFilter && !(user.relation == 0 || user.relation == 6 || user.relation == 1 || user.relation == null)) {
              relationFilteredIds.add(user.userID);
              skippedRelationCount++;
              continue;
            }

            // Check profile access filter (using is_closed)
            bool isLimitedAccess = _isProfileAccessLimited(user);
            if (isLimitedAccess) {
              profileAccessLimitedIds.add(user.userID);
              if (skipClosedProfiles) {
                skippedClosedCount++;
                continue; // Skip this user
              }
            }

            // Add user if not already present
            if (foundUsers.add(user)) {
              addedCount++;
            }
          }
          
          print(
              "Group $groupId / City ${cityId ?? 'any'}: Found ${users.length}, Added $addedCount new. Skipped: $skippedAlreadySeenCount (seen), $skippedRelationCount (relation), $skippedClosedCount (closed). Total unique: ${foundUsers.length}");

        } catch (e) {
          print("Error during users.search (group $groupId, city ${cityId ?? 'any'}): $e");
          
          if (e.toString().contains('Too many requests') || e.toString().contains('rate limit')) {
            print("Rate limit hit, adding longer delay before retry");
            await Future.delayed(Duration(seconds: 2));
            
            // Try again with same group/city
            try {
              final randomDelay = 100 + random.nextInt(400);
              await Future.delayed(Duration(milliseconds: 200 + randomDelay));
              
              print("Retrying: Group $groupId / City ${cityId ?? 'any'}");
              
              final List<VKGroupUser> retryUsers = await _apiProvider.searchUsers(
                vkToken: vkToken,
                groupId: groupId,
                cityId: cityId,
                ageFrom: ageFrom,
                ageTo: ageTo,
                sex: sexFilter,
                count: searchLimitPerRequest,
                offset: 0,
                groupURL: groupURL,
              );
              
              // Process users from retry (same logic as above)
              int addedCount = 0;
              int skippedClosedCount = 0;
              int skippedRelationCount = 0;
              int skippedAlreadySeenCount = 0;

              for (var user in retryUsers) {
                if (skippedIDs.contains(user.userID)) {
                  skippedAlreadySeenCount++;
                  continue;
                }

                if (skipRelationFilter && !(user.relation == 0 || user.relation == 6 || user.relation == 1 || user.relation == null)) {
                  relationFilteredIds.add(user.userID);
                  skippedRelationCount++;
                  continue;
                }

                bool isLimitedAccess = _isProfileAccessLimited(user);
                if (isLimitedAccess) {
                  profileAccessLimitedIds.add(user.userID);
                  if (skipClosedProfiles) {
                    skippedClosedCount++;
                    continue;
                  }
                }

                if (foundUsers.add(user)) {
                  addedCount++;
                }
              }
              
              print("RETRY Group $groupId / City ${cityId ?? 'any'}: Found ${retryUsers.length}, Added $addedCount new. Total unique: ${foundUsers.length}");
              
            } catch (retryError) {
              print("Retry failed for group $groupId / city ${cityId ?? 'any'}: $retryError");
              // Continue to next city/group after retry failure
            }
          } else {
            reachedVkLimit = true; // Assume a potentially blocking error
          }
        }
      } // End city loop
      
      if (reachedVkLimit) break; // Stop searching groups
    } // End group loop

    // 4. Convert Set to List and Return
    final usersList = foundUsers.toList();
    print("Total unique users found across all groups/cities: ${usersList.length}");
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
        isClosed: baseProfileInfo.isClosed, // Include the field
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

  // Helper method to check if a profile has limited access based on is_closed and canWritePrivateMessage
  bool _isProfileAccessLimited(VKGroupUser user) {
    return user.isClosed == true || user.canWritePrivateMessage == false;
  }

  // sendMessage (Remains the same)
  Future<bool> sendMessage(
      String vkToken, String userId, String message) async {
    return await _apiProvider.sendMessage(vkToken, userId, message);
  }
}

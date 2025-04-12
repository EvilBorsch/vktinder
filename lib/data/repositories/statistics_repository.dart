import 'dart:async';


import 'package:get_storage/get_storage.dart';

import 'dart:convert';

import 'package:vktinder/data/models/vk_group_user.dart';

class StatisticsRepository {
  final _storage = GetStorage();

  final _groupUserKey = "statistics_liked_users";
  final _skippedUsersKey = "statistics_skipped_users";

  Future<void> saveLikedUser(String groupID, VKGroupUser user) async {
    var dbGroupUsers = await getLikedUsers();
    if (!dbGroupUsers.containsKey(groupID)){
      dbGroupUsers[groupID] = [];
    }
    dbGroupUsers[groupID]!.add(user);

    await _storage.write(_groupUserKey, jsonEncode(dbGroupUsers));
  }

  Future<void> saveSkippedUser(String vkID) async {
    var dbSkippedUsers = await getSkippedUsers();
    dbSkippedUsers.add(vkID);
    await _storage.write(_skippedUsersKey, jsonEncode(dbSkippedUsers));
  }

  Future<Map<String, List<VKGroupUser>>> getLikedUsers() async {
    var rawValue = await _storage.read(_groupUserKey) ?? "{}";
    final Map<String, dynamic> rawDBGroupUsers = jsonDecode(rawValue);
    final Map<String, List<VKGroupUser>> dbGroupUsers = {};

    rawDBGroupUsers.forEach((groupID, rawGroupUsersList){
      if (!dbGroupUsers.containsKey(groupID)){
        dbGroupUsers[groupID] = [];
      }
      rawGroupUsersList.forEach((rawUser){
        dbGroupUsers[groupID]!.add(VKGroupUser.fromJson(rawUser));
      });
    });

    return dbGroupUsers;
  }

  Future<List<String>> getSkippedUsers() async {
    var rawValue = await _storage.read(_skippedUsersKey) ?? "[]";
    List<dynamic> rawDbSkippedUsers = jsonDecode(rawValue);
    final List<String> resSkippedUsers = [];
    for (var user in rawDbSkippedUsers) {
      resSkippedUsers.add(jsonEncode(user));
    }
    return resSkippedUsers;
  }




}

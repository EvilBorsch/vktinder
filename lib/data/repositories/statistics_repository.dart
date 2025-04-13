import 'dart:async';

import 'package:get_storage/get_storage.dart';
import 'package:vktinder/data/models/statistics.dart';

import 'dart:convert';


class StatisticsRepository {
  final _storage = GetStorage();

  final _groupUserKey = "statistics_liked_users";
  final _skippedUsersKey = "statistics_skipped_users";

  Future<void> saveUserAction(String groupURL, StatisticsUserAction user) async {
    var dbGroupUsers = await getUserActions();
    if (!dbGroupUsers.containsKey(groupURL)) {
      dbGroupUsers[groupURL] = [];
    }
    dbGroupUsers[groupURL]!.add(user);

    await _storage.write(_groupUserKey, jsonEncode(dbGroupUsers));
  }

  Future<void> saveSkippedUser(String vkID) async {
    var dbSkippedUsers = await getSkippedUsers();
    dbSkippedUsers.add(vkID);
    await _storage.write(_skippedUsersKey, jsonEncode(dbSkippedUsers));
  }

  Future<Map<String, List<StatisticsUserAction>>> getUserActions() async {
    var rawValue = await _storage.read(_groupUserKey) ?? "{}";
    final Map<String, dynamic> rawDBGroupUsers = jsonDecode(rawValue);
    final Map<String, List<StatisticsUserAction>> dbGroupUsers = {};

    rawDBGroupUsers.forEach((groupURL, rawGroupUsersList) {
      if (!dbGroupUsers.containsKey(groupURL)) {
        dbGroupUsers[groupURL] = [];
      }
      rawGroupUsersList.forEach((rawUser) {
        dbGroupUsers[groupURL]!.add(StatisticsUserAction.fromJson(rawUser));
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

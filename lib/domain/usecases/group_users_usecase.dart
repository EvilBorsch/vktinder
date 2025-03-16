import 'dart:convert';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vktinder/data/models/vk_group_user.dart';

class GroupUsersUsecase extends GetxService {
  // Initialize method for GetxService
  Future<GroupUsersUsecase> init() async {
    return this;
  }

  Future<List<VKGroupUser>> get(String vkToken) async {
    var res = await _loadFromCache(vkToken);
    if (res.isEmpty) {
      res = await _getFromRemote(vkToken);
      await _saveToCache(res);
    }
    return res;
  }

  Future<List<VKGroupUser>> removeFirst(
    String vkToken,
    List<VKGroupUser> users,
  ) async {
    if (users.length == 1) {
      return await get(vkToken);
    }
    users.removeAt(0);
    await _saveToCache(users);
    return users;
  }

  Future<List<VKGroupUser>> _loadFromCache(String vkToken) async {
    if (vkToken.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      final storedCardsRaw = prefs.getString('persisted_cards');
      if (storedCardsRaw != null && storedCardsRaw.isNotEmpty) {
        final List decoded = jsonDecode(storedCardsRaw);
        final res =
            decoded
                .map(
                  (item) => VKGroupUser.fromJson(item as Map<String, dynamic>),
                )
                .toList();
        return res;
      }
    }
    return [];
  }

  Future<List<VKGroupUser>> _getFromRemote(String vkToken) async {
    final List<VKGroupUser> res = [];
    for (int i = 0; i < 5; i++) {
      final randomWord = 'Random $i)}';
      res.add(
        VKGroupUser(
          name: '$randomWord + $vkToken',
          surname: "constant surname",
        ),
      );
    }
    return res;
  }

  Future<void> _saveToCache(List<VKGroupUser> users) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('persisted_cards', jsonEncode(users));
  }
}
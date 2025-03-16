import 'dart:convert';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:vktinder/data/models/vk_group_user.dart';

class LocalStorageProvider extends GetxService {
  final _storage = GetStorage();

  // User cards storage
  static const String _cardsKey = 'persisted_cards';

  // Settings storage keys
  static const String _vkTokenKey = 'vk_token';
  static const String _defaultMessageKey = 'default_message';
  static const String _themeKey = 'theme_mode';

  // Cards methods
  Future<List<VKGroupUser>> getStoredCards() async {
    final storedCardsRaw = _storage.read(_cardsKey);
    if (storedCardsRaw != null) {
      try {
        final List decoded = jsonDecode(storedCardsRaw);
        return decoded
            .map((item) => VKGroupUser.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (e) {
        return [];
      }
    }
    return [];
  }

  Future<void> saveCards(List<VKGroupUser> cards) async {
    await _storage.write(_cardsKey, jsonEncode(cards));
  }

  // Settings methods
  String getVkToken()  {
    return _storage.read(_vkTokenKey) ?? '';
  }

  Future<void> saveVkToken(String token) async {
    await _storage.write(_vkTokenKey, token);
  }

  String getDefaultMessage()  {
    return _storage.read(_defaultMessageKey) ?? '';
  }

  Future<void> saveDefaultMessage(String message) async {
    await _storage.write(_defaultMessageKey, message);
  }

  String getTheme()  {
    return _storage.read(_themeKey) ?? 'system';
  }

  Future<void> saveTheme(String theme) async {
    await _storage.write(_themeKey, theme);
  }
}
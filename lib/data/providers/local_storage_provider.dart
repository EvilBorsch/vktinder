import 'dart:convert';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:vktinder/data/models/vk_group_user.dart';

class LocalStorageProvider extends GetxService {
  final _storage = GetStorage();

  // User cards storage
  static const String _cardsKey = 'persisted_cards'; // Keep this if still needed for some caching

  // Settings storage keys
  static const String _vkTokenKey = 'vk_token';
  static const String _defaultMessageKey = 'default_message';
  static const String _themeKey = 'theme_mode';
  // --- NEW KEYS ---
  static const String _citiesKey = 'search_cities'; // Stores List<String> as JSON
  static const String _ageFromKey = 'search_age_from'; // Stores int?
  static const String _ageToKey = 'search_age_to'; // Stores int?
  static const String _groupUrlsKey = 'search_group_urls'; // Stores List<String> as JSON
  // --- END NEW KEYS ---

  // Cards methods (keep if still needed, but maybe less relevant with search)
  Future<List<VKGroupUser>> getStoredCards() async {
    final storedCardsRaw = _storage.read(_cardsKey);
    if (storedCardsRaw != null) {
      try {
        final List decoded = jsonDecode(storedCardsRaw);
        return decoded
            .map((item) => VKGroupUser.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (e) {
        print("Error decoding stored cards: $e");
        await _storage.remove(_cardsKey); // Clear corrupted cache
        return [];
      }
    }
    return [];
  }

  Future<void> saveCards(List<VKGroupUser> cards) async {
    try {
      await _storage.write(_cardsKey, jsonEncode(cards.map((e) => e.toJson()).toList()));
    } catch (e) {
      print("Error encoding cards for storage: $e");
    }
  }

  // --- EXISTING Settings methods ---
  String getVkToken() {
    return _storage.read(_vkTokenKey) ?? '';
  }

  Future<void> saveVkToken(String token) async {
    await _storage.write(_vkTokenKey, token);
  }

  String getDefaultMessage() {
    return _storage.read(_defaultMessageKey) ?? 'Привет! Как дела?'; // Provide a default
  }

  Future<void> saveDefaultMessage(String message) async {
    await _storage.write(_defaultMessageKey, message);
  }

  String getTheme() {
    return _storage.read(_themeKey) ?? 'system';
  }

  Future<void> saveTheme(String theme) async {
    await _storage.write(_themeKey, theme);
  }

  // --- NEW Settings methods ---
  List<String> getCities() {
    final storedCities = _storage.read<String>(_citiesKey);
    print("Raw stored cities data: $storedCities");

    if (storedCities != null && storedCities.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(storedCities);
        final List<String> cities = decoded.map((item) => item.toString()).toList();
        print("Decoded cities: $cities");
        return cities;
      } catch (e) {
        print("Error decoding cities: $e");
        _storage.remove(_citiesKey); // Clear corrupted data
        return [];
      }
    }
    return []; // Default to empty list
  }

  Future<void> saveCities(List<String> cities) async {
    print("Saving cities to storage: $cities");
    final String encoded = jsonEncode(cities);
    print("Encoded cities: $encoded");
    await _storage.write(_citiesKey, encoded);

    // Verify save
    final saved = _storage.read<String>(_citiesKey);
    print("Verified raw cities in storage: $saved");
  }


  (int?, int?) getAgeRange() {
    final ageFrom = _storage.read<int?>(_ageFromKey);
    final ageTo = _storage.read<int?>(_ageToKey);
    return (ageFrom, ageTo);
  }

  Future<void> saveAgeRange(int? ageFrom, int? ageTo) async {
    if (ageFrom == null) {
      await _storage.remove(_ageFromKey);
    } else {
      await _storage.write(_ageFromKey, ageFrom);
    }
    if (ageTo == null) {
      await _storage.remove(_ageToKey);
    } else {
      await _storage.write(_ageToKey, ageTo);
    }
  }

  List<String> getGroupUrls() {
    final storedUrls = _storage.read<String>(_groupUrlsKey);
    if (storedUrls != null && storedUrls.isNotEmpty) {
      try {
        return List<String>.from(jsonDecode(storedUrls));
      } catch (e) {
        print("Error decoding group URLs: $e");
        _storage.remove(_groupUrlsKey); // Clear corrupted data
        return [];
      }
    }
    // --- ADD A DEFAULT GROUP FOR TESTING/INITIAL USE ---
    return ["https://vk.com/team"]; // Example default
    // return []; // Default to empty list
  }

  Future<void> saveGroupUrls(List<String> urls) async {
    await _storage.write(_groupUrlsKey, jsonEncode(urls));
  }
}

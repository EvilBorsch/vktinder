// --- File: lib/data/providers/local_storage_provider.dart ---
import 'dart:convert';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:vktinder/data/models/vk_group_user.dart';
import 'package:vktinder/data/providers/hive_storage_provider.dart';

class LocalStorageProvider extends GetxService {
  final _storage = GetStorage();

  // --- Card Stack Persistence ---
  // Using Hive for persisted cards

  // Settings storage keys
  static const String _vkTokenKey = 'vk_token';
  static const String _defaultMessageKey = 'default_message';
  static const String _themeKey = 'theme_mode';
  static const String _citiesKey = 'search_cities_v2';
  static const String _ageFromKey = 'search_age_from';
  static const String _ageToKey = 'search_age_to';
  static const String _groupUrlsKey = 'search_group_urls_v3';
  static const String _groupInfosKey = 'search_group_infos_v1';
  static const String _cityInfosKey = 'search_city_infos_v1';
  static const String _sexFilterKey = 'search_sex_filter';
  static const String _skipClosedProfilesKey = 'skip_closed_profiles_v2';
  static const String _showClosedProfilesWithMessageAbilityKey = 'show_closed_profiles_with_message_ability';
  static const String _skipRelationFilterKey = 'skip_relation_filter';

  // Hive provider for persisted cards
  HiveStorageProvider? _hiveProvider;

  // Getter for _hiveProvider that ensures it's initialized
  HiveStorageProvider get hiveProvider {
    if (_hiveProvider == null) {
      try {
        _hiveProvider = Get.find<HiveStorageProvider>();
      } catch (e) {
        print("Error finding HiveStorageProvider: $e");
        print("Will retry on next access");
      }
    }
    if (_hiveProvider == null) {
      throw Exception("HiveStorageProvider not found. Make sure it's initialized before using LocalStorageProvider.");
    }
    return _hiveProvider!;
  }

  // --- Card Stack Methods ---

  Future<void> savePersistedCards(List<VKGroupUser> users) async {
    try {
      await hiveProvider.savePersistedCards(users);
      print("LocalStorageProvider: Saved ${users.length} cards to Hive persisted stack.");
    } catch (e, stackTrace) {
      print("Error saving persisted cards to Hive: $e\n$stackTrace");
      // Handle potential errors
      if (e is OutOfMemoryError) {
        print("FATAL: OutOfMemoryError while saving persisted stack to Hive. Data might be lost.");
        // Consider clearing the broken data to prevent load errors next time
        await clearPersistedCards();
      }
    }
  }

  Future<List<VKGroupUser>> loadPersistedCards() async {
    try {
      final List<Map<String, dynamic>> userMaps = await hiveProvider.loadPersistedCards();
      final List<VKGroupUser> loadedUsers = userMaps
          .map((userData) {
        try {
          return VKGroupUser.fromJson(userData);
        } catch (e) {
          print("Error creating VKGroupUser from Hive data: $e \nData: $userData");
          return null; // Skip corrupted user data
        }
      })
          .whereType<VKGroupUser>() // Filter out nulls
          .toList();
      print("LocalStorageProvider: Loaded ${loadedUsers.length} cards from Hive persisted stack.");
      return loadedUsers;
    } catch (e) {
      print("Error loading persisted cards from Hive: $e");
      return [];
    }
  }

  Future<void> clearPersistedCards() async {
    await hiveProvider.clearPersistedCards();
    print("LocalStorageProvider: Cleared Hive persisted card stack.");
  }


  // --- EXISTING Settings methods ---
  String getVkToken() {
    return _storage.read(_vkTokenKey) ?? '';
  }

  Future<void> saveVkToken(String token) async {
    await _storage.write(_vkTokenKey, token);
  }

  String getDefaultMessage() {
    return _storage.read(_defaultMessageKey) ?? 'Привет';
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

  // --- NEW Settings methods (Unchanged from previous version) ---
  List<String> getCities() {
    final storedCities = _storage.read<String>(_citiesKey);
    if (storedCities != null && storedCities.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(storedCities);
        return decoded.map((item) => item.toString()).toList();
      } catch (e) { print("Error decoding cities: $e"); _storage.remove(_citiesKey); return []; }
    }
    return ["Москва"];
  }

  Future<void> saveCities(List<String> cities) async {
    try {
      await _storage.write(_citiesKey, jsonEncode(cities));
    } catch (e) { print("Error encoding/saving cities: $e"); }
  }

  (int?, int?) getAgeRange() {
    final ageFrom = _storage.read<int?>(_ageFromKey);
    final ageTo = _storage.read<int?>(_ageToKey);
    return (ageFrom, ageTo);
  }

  Future<void> saveAgeRange(int? ageFrom, int? ageTo) async {
    if (ageFrom == null) { await _storage.remove(_ageFromKey); }
    else { await _storage.write(_ageFromKey, ageFrom); }
    if (ageTo == null) { await _storage.remove(_ageToKey); }
    else { await _storage.write(_ageToKey, ageTo); }
  }

  int getSexFilter() {
    return _storage.read<int>(_sexFilterKey) ?? 1; // Default female
  }

  Future<void> saveSexFilter(int sex) async {
    await _storage.write(_sexFilterKey, sex);
  }

  List<String> getGroupUrls() {
    final storedUrls = _storage.read<String>(_groupUrlsKey);
    if (storedUrls != null && storedUrls.isNotEmpty) {
      try { return List<String>.from(jsonDecode(storedUrls)); }
      catch (e) { print("Error decoding group URLs: $e"); _storage.remove(_groupUrlsKey); return []; }
    }
    return ["https://vk.com/team"]; // Default example
  }

  List<Map<String, dynamic>> getGroupInfos() {
    final storedInfos = _storage.read<String>(_groupInfosKey);
    if (storedInfos != null && storedInfos.isNotEmpty) {
      try { 
        final List<dynamic> decoded = jsonDecode(storedInfos);
        return decoded.map((item) => item as Map<String, dynamic>).toList();
      }
      catch (e) { 
        print("Error decoding group infos: $e"); 
        _storage.remove(_groupInfosKey); 
        return []; 
      }
    }
    return []; // No default for group infos
  }

  Future<void> saveGroupUrls(List<String> urls) async {
    try { await _storage.write(_groupUrlsKey, jsonEncode(urls)); }
    catch (e) { print("Error encoding/saving group URLs: $e"); }
  }

  Future<void> saveGroupInfos(List<Map<String, dynamic>> infos) async {
    try { await _storage.write(_groupInfosKey, jsonEncode(infos)); }
    catch (e) { print("Error encoding/saving group infos: $e"); }
  }

  List<Map<String, dynamic>> getCityInfos() {
    final storedInfos = _storage.read<String>(_cityInfosKey);
    if (storedInfos != null && storedInfos.isNotEmpty) {
      try { 
        final List<dynamic> decoded = jsonDecode(storedInfos);
        return decoded.map((item) => item as Map<String, dynamic>).toList();
      }
      catch (e) { 
        print("Error decoding city infos: $e"); 
        _storage.remove(_cityInfosKey); 
        return []; 
      }
    }
    return []; // No default for city infos
  }

  Future<void> saveCityInfos(List<Map<String, dynamic>> infos) async {
    try { await _storage.write(_cityInfosKey, jsonEncode(infos)); }
    catch (e) { print("Error encoding/saving city infos: $e"); }
  }

  bool getSkipClosedProfiles() {
    return _storage.read<bool>(_skipClosedProfilesKey) ?? true; // Default true
  }

  Future<void> saveSkipClosedProfiles(bool skip) async {
    await _storage.write(_skipClosedProfilesKey, skip);
  }

  bool getShowClosedProfilesWithMessageAbility() {
    return _storage.read<bool>(_showClosedProfilesWithMessageAbilityKey) ?? false; // Default false
  }

  Future<void> saveShowClosedProfilesWithMessageAbility(bool show) async {
    await _storage.write(_showClosedProfilesWithMessageAbilityKey, show);
  }

  bool getSkipRelationFilter() {
    return _storage.read<bool>(_skipRelationFilterKey) ?? true; // Default true
  }

  Future<void> saveSkipRelationFilter(bool skip) async {
    await _storage.write(_skipRelationFilterKey, skip);
  }
}

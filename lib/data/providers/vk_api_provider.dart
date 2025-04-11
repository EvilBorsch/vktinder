// lib/data/providers/vk_api_provider.dart
import 'package:dio/dio.dart';
import 'package:get/get.dart' as getx;
import 'package:vktinder/data/models/vk_group_user.dart';
import 'package:vktinder/data/models/vk_group_info.dart'; // Import the new model
import 'dart:math'; // For random_id
import 'dart:async'; // Required for Future.delayed

class VkApiProvider extends getx.GetxService {
  // --- START: MOCK DATA SWITCH ---
  /// Set to true to use local mock data instead of real VK API calls.
  /// Ideal for development, testing UI, or offline work.
  static const bool _useMockData = false; // <-- CHANGE THIS FLAG (true/false) TO SWITCH MODES
  // --- END: MOCK DATA SWITCH ---

  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://api.vk.com/method/',
    connectTimeout: const Duration(seconds: 15), // Increased timeout
    receiveTimeout: const Duration(seconds: 15), // Increased timeout
    queryParameters: {
      'v': '5.199', // Specify a recent API version
    },
  ));
  final String _apiVersion = '5.199';

  // Helper to handle VK API errors (remains the same)
  dynamic _handleResponse(Response response) {
    if (response.statusCode == 200 && response.data != null) {
      if (response.data['error'] != null) {
        final error = response.data['error'];
        // Specific error handling for privacy
        if (error['error_code'] == 15) { // Access denied (e.g., private profile)
          print('VK API Privacy Error [15]: ${error['error_msg']}');
          // You might want to throw a specific exception type here
          // or return a specific value indicating privacy restrictions.
          // For now, we'll let it throw a general DioException below.
        }
        final errorMessage = error['error_msg'] ?? 'Unknown VK API error';
        final errorCode = error['error_code'] ?? -1;
        print('VK API Error Response: ${response.data}');
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'VK API Error [$errorCode]: $errorMessage',
          type: DioExceptionType.unknown, // Or specific type if applicable
        );
      }
      if (response.data is Map && response.data.containsKey('response')) {
        return response.data['response'];
      } else {
        print('VK API Success Response (no "response" key): ${response.data}');
        return response.data;
      }
    } else {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: 'Failed to communicate with VK API (Status: ${response.statusCode})',
        type: DioExceptionType.badResponse,
      );
    }
  }


  // --- Updated Mock Data Definitions ---

  // Mock data for getGroupUsers (remains the same)
  Future<List<VKGroupUser>> _getMockGroupUsers() async {
    // ... existing mock code ...
    print("[MOCK] Returning mock data for getGroupUsers");
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay

    final mockResponse = {
      "response": {
        "count": 5,
        "items": [
          {
            "id": 101,
            "first_name": "Ольга",
            "last_name": "Тестовая",
            "photo_100": "https://via.placeholder.com/100/FF0000/FFFFFF?text=Mock1",
            "photo_200": "https://via.placeholder.com/200/FF0000/FFFFFF?text=Mock1-200",
            "sex": 1, // 1=female
            "online": 1 // 1=online, 0=offline
          },
          {
            "id": 102,
            "first_name": "Елена",
            "last_name": "Пример",
            "photo_100": "https://via.placeholder.com/100/00FF00/FFFFFF?text=Mock2",
            "photo_200": "https://via.placeholder.com/200/00FF00/FFFFFF?text=Mock2-200",
            "sex": 1,
            "online": 0
          },
          {
            "id": 103,
            "first_name": "Мария",
            "last_name": "Разработкова",
            "photo_100": "https://via.placeholder.com/100/0000FF/FFFFFF?text=Mock3",
            "photo_200": "https://via.placeholder.com/200/0000FF/FFFFFF?text=Mock3-200",
            "sex": 1,
            "online": 1
          },
          {
            "id": 104,
            "first_name": "Александр",
            "last_name": "Тестов",
            "photo_100": "https://via.placeholder.com/100/FF00FF/FFFFFF?text=Mock4",
            "photo_200": "https://via.placeholder.com/200/FF00FF/FFFFFF?text=Mock4-200",
            "sex": 2, // 2=male
            "online": 0
          },
          {
            "id": 105,
            "first_name": "Иван",
            "last_name": "Примеров",
            "photo_100": "https://via.placeholder.com/100/FFFF00/000000?text=Mock5",
            "photo_200": "https://via.placeholder.com/200/FFFF00/000000?text=Mock5-200",
            "sex": 2,
            "online": 1
          }
        ]
      }
    };

    final List userList = mockResponse['response']?['items'] as List<dynamic>;
    return userList
        .map((userData) => VKGroupUser.fromJson(userData as Map<String, dynamic>))
        .toList();
  }

  // Mock data for getFullProfile (remains mostly the same, just ensure groups is handled)
  Future<VKGroupUser> _getMockFullProfile(String userID) async {
    // ... existing mock profile generation code ...
    print("[MOCK] Returning mock data for getFullProfile (userID: $userID)");
    await Future.delayed(const Duration(milliseconds: 400));

    // Base profile data template
    final mockProfileBase = {
      "id": int.tryParse(userID) ?? 101,
      "first_name": "Ольга",
      "last_name": "Тестовая",
      "photo_max_orig": "https://via.placeholder.com/800x600/FF0000/FFFFFF?text=MockFull+$userID",
      "photo_400_orig": "https://via.placeholder.com/400x300/FF0000/FFFFFF?text=MockFull+$userID",
      "photo_200": "https://via.placeholder.com/200/FF0000/FFFFFF?text=MockFull+$userID",
      "photo_100": "https://via.placeholder.com/100/FF0000/FFFFFF?text=MockFull+$userID",
      "sex": 1,
      "bdate": "15.5.1995",
      "city": {"id": 1, "title": "Москва"},
      "country": {"id": 1, "title": "Россия"},
      "interests": "flutter, разработка, котики, путешествия",
      "about": "Это тестовое описание профиля. Люблю программировать и гулять.",
      "status": "Тестирую приложение \uD83D\uDE80",
      "relation": 1, // 1=single
      "screen_name": "mock_user_$userID",
      "online": 1,
      "last_seen": {
        "time": DateTime.now().millisecondsSinceEpoch ~/ 1000 - 3600, // 1 hour ago
        "platform": 7 // Mobile app
      },
      // Add empty groups list, it will be populated by mock group calls later
      "groups": [],
      "photos": [],
    };

    // Customize based on userID for variety
    if (userID == "101") {
      // Keep default Olga
    } else if (userID == "102") {
      mockProfileBase["first_name"] = "Елена";
      mockProfileBase["last_name"] = "Пример";
      // ... other customizations ...
      mockProfileBase["online"] = 0;
    } else if (userID == "103") {
      mockProfileBase["first_name"] = "Мария";
      mockProfileBase["last_name"] = "Разработкова";
      // ... other customizations ...
    } else if (userID == "104") {
      mockProfileBase["first_name"] = "Александр";
      mockProfileBase["last_name"] = "Тестов";
      mockProfileBase["sex"] = 2; // male
      // ... other customizations ...
      mockProfileBase["online"] = 0;
    } else if (userID == "105") {
      mockProfileBase["first_name"] = "Иван";
      mockProfileBase["last_name"] = "Примеров";
      mockProfileBase["sex"] = 2; // male
      // ... other customizations ...
    }
    // Update image URLs based on sex to have different placeholders
    final colorCode = mockProfileBase["sex"] == 1 ? "FF0000" : "0000FF"; // Red for female, Blue for male
    final baseUrl = "https://via.placeholder.com";

    mockProfileBase["photo_max_orig"] = "$baseUrl/800x600/$colorCode/FFFFFF?text=${mockProfileBase["first_name"]}_$userID";
    mockProfileBase["photo_400_orig"] = "$baseUrl/400x300/$colorCode/FFFFFF?text=${mockProfileBase["first_name"]}_$userID";
    mockProfileBase["photo_200"] = "$baseUrl/200/$colorCode/FFFFFF?text=${mockProfileBase["first_name"]}_$userID";
    mockProfileBase["photo_100"] = "$baseUrl/100/$colorCode/FFFFFF?text=${mockProfileBase["first_name"]}_$userID";

    // MOCK: Assign some mock photos directly for simplicity in mock mode
    final mockPhotos = await _getMockUserPhotos(userID);
    mockProfileBase["photos"] = mockPhotos;

    return VKGroupUser.fromJson(mockProfileBase as Map<String, dynamic>);
  }


  // Mock data for getUserPhotos (remains the same)
  Future<List<String>> _getMockUserPhotos(String userID) async {
    // ... existing mock code ...
    print("[MOCK] Returning mock data for getUserPhotos (userID: $userID)");
    await Future.delayed(const Duration(milliseconds: 600));

    // Get mock user sex to use appropriate color scheme (if available)
    int defaultSex = 0; // 0=not specified, 1=female, 2=male
    if (userID == "101" || userID == "102" || userID == "103") defaultSex = 1;
    if (userID == "104" || userID == "105") defaultSex = 2;

    // Color scheme based on sex
    final String baseColor = defaultSex == 1 ? "FF0088" : defaultSex == 2 ? "0088FF" : "888888";

    // Base URL with different sizes and slight color variations
    final baseUrl = "https://via.placeholder.com";

    // Generate a more realistic photo collection (5-8 photos)
    final int photoCount = 5 + (int.tryParse(userID.substring(userID.length - 1)) ?? 0) % 4;

    List<String> photos = [];
    for (int i = 1; i <= photoCount; i++) {
      // Vary dimensions to simulate real photos
      final int width = 600 + (i * 40);
      final int height = 400 + ((i * 30) % 200);

      // Slight color variations
      final String colorHex = baseColor.substring(0, 2) +
          ((int.parse(baseColor.substring(2, 4), radix: 16) + (i * 10)) % 256).toRadixString(16).padLeft(2, '0') +
          baseColor.substring(4);

      photos.add("$baseUrl/${width}x$height/$colorHex/FFFFFF?text=Photo_${userID}_$i");
    }

    return photos;
  }

  // Mock data for sendMessage (remains the same)
  Future<bool> _sendMockMessage(String userId, String message) async {
    // ... existing mock code ...
    print("[MOCK] Simulating sending message to $userId: '$message'");
    await Future.delayed(const Duration(milliseconds: 300));

    // Randomly fail 10% of the time to simulate network issues
    final shouldSucceed = Random().nextDouble() > 0.1;

    if (!shouldSucceed) {
      print("[MOCK] Simulated message failure");
    } else {
      print("[MOCK] Message sent successfully");
    }

    return shouldSucceed;
  }

  // --- START: NEW MOCK METHODS ---
  // Mock data for getUserSubscriptions
  Future<List<int>> _getMockUserSubscriptionIds(String userID) async {
    print("[MOCK] Returning mock subscription IDs for userID: $userID");
    await Future.delayed(const Duration(milliseconds: 350));
    // Return different sets of IDs for different test users
    switch (userID) {
      case "101": return [1, 2, 3, 456, 789]; // Groups and Pages
      case "102": return [1, 5, 10, 12345];
      case "103": return []; // User with no public groups/pages
      case "104": return [2, 6, 7];
      case "105": return [1, 3, 7, 999];
      default: return [1, 2, 99]; // Default
    }
  }

  // Mock data for getGroupsById
  Future<List<VKGroupInfo>> _getMockGroupsById(List<String> groupIds) async {
    print("[MOCK] Returning mock group details for IDs: ${groupIds.join(',')}");
    if (groupIds.isEmpty) return [];
    await Future.delayed(const Duration(milliseconds: 550));

    final List<Map<String, dynamic>> mockGroupsData = [
      {"id": 1, "name": "Flutter Developers", "screen_name": "flutterdev", "photo_100": "https://via.placeholder.com/100/AAAAAA/FFFFFF?text=Flutter", "members_count": 150000, "type": "page"},
      {"id": 2, "name": "Интересные Факты", "screen_name": "facts", "photo_100": "https://via.placeholder.com/100/00AAAA/FFFFFF?text=Facts", "members_count": 2500000, "type": "page"},
      {"id": 3, "name": "Клуб Путешественников", "screen_name": "travel_club", "photo_100": "https://via.placeholder.com/100/AA00AA/FFFFFF?text=Travel", "members_count": 50000, "type": "group"},
      {"id": 5, "name": "Любители Котиков", "screen_name": "cat_lovers", "photo_100": "https://via.placeholder.com/100/FFAA00/000000?text=Cats", "members_count": 1234567, "type": "group"},
      {"id": 6, "name": "Новости IT", "screen_name": "it_news", "photo_100": "https://via.placeholder.com/100/00FFAA/000000?text=IT", "members_count": 300000, "type": "page"},
      {"id": 7, "name": "Кино и Сериалы", "screen_name": "kino", "photo_100": "https://via.placeholder.com/100/AA0000/FFFFFF?text=Kino", "members_count": 800000, "type": "page"},
      {"id": 10, "name": "Рецепты", "screen_name": "recipes_vk", "photo_100": "https://via.placeholder.com/100/00AA00/FFFFFF?text=Food", "members_count": 950000, "type": "page"},
      {"id": 99, "name": "Тестовая Группа 99", "screen_name": "test99", "photo_100": "https://via.placeholder.com/100/CCCCCC/000000?text=Test99", "members_count": 10, "type": "group"},
      {"id": 456, "name": "Очень Длинное Название Группы", "screen_name": "long_name", "photo_100": "https://via.placeholder.com/100/999999/FFFFFF?text=Long", "members_count": 5, "type": "group"},
      {"id": 789, "name": "Музыка", "screen_name": "music", "photo_100": "https://via.placeholder.com/100/FF00FF/FFFFFF?text=Music", "members_count": 4200000, "type": "page"},
      {"id": 999, "name": "Игры Онлайн", "screen_name": "games", "photo_100": "https://via.placeholder.com/100/00FFFF/000000?text=Games", "members_count": 765432, "type": "page"},
      {"id": 12345, "name": "Закрытая Группа", "screen_name": "private_test", "photo_100": "https://vk.com/images/community_100.png", "members_count": 15, "type": "group"},
    ];

    // Filter mock data to only return groups matching the requested IDs
    final List<int> requestedIdsInt = groupIds.map((id) => int.tryParse(id) ?? -1).where((id) => id != -1).toList();
    final results = mockGroupsData
        .where((groupData) => requestedIdsInt.contains(groupData['id'] as int))
        .map((groupData) => VKGroupInfo.fromJson(groupData))
        .toList();

    // Simulate missing some groups (if more than 3 are requested, return only 3)
    return results.take(8).toList();
  }
  // --- END: NEW MOCK METHODS ---

  // --- API Methods with Mock Switch ---

  Future<List<VKGroupUser>> getGroupUsers(String vkToken, String groupId) async {
    // --- MOCK SWITCH ---
    if (_useMockData) {
      return _getMockGroupUsers();
    }
    // --- END MOCK SWITCH ---

    // Real API Call Logic (updated fields)
    // ... (existing code remains the same) ...
    if (vkToken.isEmpty || groupId.isEmpty) {
      print("Error: VK Token or Group ID is missing for getGroupUsers.");
      throw ArgumentError('VK Token and Group ID must be provided.');
    }
    try {
      print("VK API Call: groups.getMembers (groupId: $groupId)");
      final response = await _dio.get(
        'groups.getMembers',
        queryParameters: {
          'group_id': groupId,
          'access_token': vkToken,
          'fields': 'id,first_name,last_name,photo_100,photo_200,sex,online', // Added photo_200
          'v': _apiVersion,
        },
      );
      final responseData = _handleResponse(response);
      if (responseData == null || responseData['items'] == null) {
        print("Warning: groups.getMembers response data or items list is null.");
        return [];
      }
      final List usersList = responseData['items'] ?? [];
      return usersList
          .map((userData) => VKGroupUser.fromJson(userData as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      print("DioError fetching group users: ${e.message}");
      if (e.response != null) { print("DioError Response Data: ${e.response?.data}"); }
      throw Exception('Failed to load group users: ${e.message}');
    } catch (e, stackTrace) {
      print("Error parsing group users: $e\n$stackTrace");
      throw Exception('Failed to parse group users data.');
    }
  }

  Future<VKGroupUser> getFullProfile(String vkToken, String userID) async {
    // --- MOCK SWITCH ---
    if (_useMockData) {
      // MOCK: Needs to be modified in the repository to also call mock group methods
      return _getMockFullProfile(userID);
    }
    // --- END MOCK SWITCH ---

    // Real API Call Logic (updated fields)
    // ... (existing code remains the same) ...
    if (vkToken.isEmpty || userID.isEmpty) {
      throw ArgumentError("VK Token and User ID must be provided for getFullProfile.");
    }
    try {
      print("VK API Call: users.get (userId: $userID)");
      final response = await _dio.get('users.get', queryParameters: {
        'user_ids': userID,
        'fields': 'id,first_name,last_name,photo_max_orig,sex,bdate,city,country,interests,about,status,relation,screen_name,online,last_seen,photo_200,photo_400_orig', // Removed groups, as it's fetched separately
        'access_token': vkToken,
        'v': _apiVersion,
      });
      final responseData = _handleResponse(response);
      if (responseData == null || responseData is! List || responseData.isEmpty) {
        print("Warning: users.get response data is null, not a list, or empty.");
        throw Exception('User profile not found or API error.');
      }
      // Create the base user object
      final user = VKGroupUser.fromJson(responseData[0] as Map<String, dynamic>);

      // Photos and Groups will be fetched and added in the repository
      return user;

    } on DioException catch (e) {
      print("DioError fetching full profile: ${e.message}");
      if (e.response != null) { print("DioError Response Data: ${e.response?.data}"); }
      throw Exception('Failed to load user profile: ${e.message}');
    } catch (e, stackTrace) {
      print("Error parsing profile: $e\n$stackTrace");
      throw Exception('Failed to parse user profile data.');
    }
  }

  Future<List<String>> getUserPhotos(String vkToken, String userID) async {
    // --- MOCK SWITCH ---
    if (_useMockData) {
      return _getMockUserPhotos(userID);
    }
    // --- END MOCK SWITCH ---

    // Real API Call Logic (remains the same)
    // ... (existing code remains the same) ...
    if (vkToken.isEmpty || userID.isEmpty) {
      throw ArgumentError("VK Token and User ID must be provided for getUserPhotos.");
    }
    try {
      print("VK API Call: photos.get (ownerId: $userID)");
      final response = await _dio.get('photos.get', queryParameters: {
        'owner_id': userID,
        'album_id': 'profile',
        'access_token': vkToken,
        'extended': 1,
        'photo_sizes': 1,
        'count': 20,
        'v': _apiVersion,
      });
      final responseData = _handleResponse(response);
      if (responseData == null || responseData['items'] == null) {
        print("Warning: photos.get response data or items list is null.");
        return [];
      }
      final List photosList = responseData['items'] ?? [];
      return photosList.map((photoData) {
        if (photoData == null || photoData['sizes'] == null) return 'https://vk.com/images/camera_200.png';
        final sizes = (photoData['sizes'] as List?) ?? [];
        if (sizes.isNotEmpty) {
          final priority = ['w', 'z', 'y', 'x', 'r', 'q', 'p', 'o', 'm', 's'];
          for(String type in priority) {
            try {
              final size = sizes.firstWhere((s) => s != null && s['type'] == type, orElse: () => null);
              if (size != null && size['url'] is String) return size['url'] as String;
            } catch (e) { print("Error accessing photo size: $e"); }
          }
          try {
            if (sizes.last != null && sizes.last['url'] is String) return sizes.last['url'] as String;
          } catch (e) { print("Error accessing last photo size: $e"); }
        }
        return 'https://vk.com/images/camera_200.png';
      }).toList();

    } on DioException catch (e) {
      print("DioError fetching user photos: ${e.message}");
      if (e.response != null) { print("DioError Response Data: ${e.response?.data}"); }
      // Don't throw an exception here, just return empty list or log it
      // throw Exception('Failed to load user photos: ${e.message}');
      print('Failed to load user photos: ${e.message}. Returning empty list.');
      return [];
    } catch (e, stackTrace) {
      print("Error parsing photos: $e\n$stackTrace");
      // Don't throw an exception here, just return empty list or log it
      // throw Exception('Failed to parse user photos data.');
      print('Failed to parse user photos data. Returning empty list.');
      return [];
    }
  }

  Future<bool> sendMessage(String vkToken, String userId, String message) async {
    // --- MOCK SWITCH ---
    if (_useMockData) {
      return _sendMockMessage(userId, message);
    }
    // --- END MOCK SWITCH ---

    // Real API Call Logic (remains the same)
    // ... (existing code remains the same) ...
    if (vkToken.isEmpty || userId.isEmpty || message.isEmpty) {
      print("Error: VK Token, User ID, or Message is missing for sendMessage.");
      return false;
    }
    try {
      print("VK API Call: messages.send (userId: $userId)");
      final response = await _dio.post('messages.send', queryParameters: {
        'user_id': userId,
        'message': message,
        'access_token': vkToken,
        'random_id': Random().nextInt(2147483647),
        'v': _apiVersion,
      });
      final responseData = _handleResponse(response);
      if (responseData != null && responseData is int) {
        print("Message sent successfully, message ID: $responseData");
        return true;
      } else {
        // Handle error code 901: Can't send messages for users without permission
        if (response.data?['error']?['error_code'] == 901) {
          print("Message send failed (Error 901): Can't send messages for users without permission.");
        } else {
          print("Message send call succeeded, but response was not the expected message ID: $responseData");
        }
        return false;
      }
    } on DioException catch (e) {
      // Specifically handle privacy-related send errors (though 901 might be caught above)
      if (e.response?.data?['error']?['error_code'] == 900 || e.response?.data?['error']?['error_code'] == 902) {
        print("DioError sending message (Privacy restriction): ${e.message}");
      } else {
        print("DioError sending message: ${e.message}");
      }
      if (e.response != null) { print("DioError Response Data: ${e.response?.data}"); }
      return false;
    } catch (e, stackTrace) {
      print("Error sending message: $e\n$stackTrace");
      return false;
    }
  }

  // --- START: NEW API METHODS ---

  /// Fetches IDs of groups and public pages the user is subscribed to.
  /// Returns a list of positive integers (group IDs).
  /// Note: Requires 'groups' permission in the VK Token.
  /// May fail due to user privacy settings. Returns empty list on failure.
  Future<List<int>> getUserSubscriptionIds(String vkToken, String userId) async {
    // --- MOCK SWITCH ---
    if (_useMockData) {
      return _getMockUserSubscriptionIds(userId);
    }
    // --- END MOCK SWITCH ---

    if (vkToken.isEmpty || userId.isEmpty) {
      print("Error: VK Token or User ID is missing for getUserSubscriptions.");
      return [];
    }
    try {
      print("VK API Call: users.getSubscriptions (userId: $userId)");
      final response = await _dio.get('users.getSubscriptions', queryParameters: {
        'user_id': userId,
        'extended': 0, // We only need the IDs here
        'access_token': vkToken,
        'v': _apiVersion,
        // 'count': 200 // Limit the number if needed, VK default is 20
      });
      final responseData = _handleResponse(response);
      // Response structure: { "users": { "count": N, "items": [...] }, "groups": { "count": M, "items": [...] } }
      if (responseData?['groups']?['items'] is List) {
        // Extract only group IDs (positive numbers)
        final List groupIdsRaw = responseData['groups']['items'];
        final List<int> groupIds = groupIdsRaw.map((id) => id as int).where((id) => id > 0).toList();
        print("Fetched ${groupIds.length} group subscription IDs for user $userId.");
        return groupIds;
      } else {
        print("Warning: users.getSubscriptions response did not contain a valid groups list.");
        return [];
      }
    } on DioException catch (e) {
      // Handle specific privacy error (15: Access denied) gracefully
      if (e.response?.data?['error']?['error_code'] == 15 || e.response?.data?['error']?['error_code'] == 30) {
        print("Could not fetch subscriptions for user $userId due to privacy settings.");
        return []; // Return empty list for privacy errors
      }
      print("DioError fetching user subscriptions: ${e.message}");
      if (e.response != null) { print("DioError Response Data: ${e.response?.data}"); }
      return []; // Return empty list on other errors
    } catch (e, stackTrace) {
      print("Error parsing user subscriptions: $e\n$stackTrace");
      return []; // Return empty list on parsing errors
    }
  }


  /// Fetches detailed information for a list of group IDs.
  Future<List<VKGroupInfo>> getGroupsById(String vkToken, List<String> groupIds) async {
    // --- MOCK SWITCH ---
    if (_useMockData) {
      return _getMockGroupsById(groupIds);
    }
    // --- END MOCK SWITCH ---

    if (vkToken.isEmpty || groupIds.isEmpty) {
      return [];
    }

    // VK API limit for groups.getById is typically 500 IDs per call.
    // We might need chunking for very large lists, but let's assume <= 500 for now.
    final idsString = groupIds.join(',');

    try {
      print("VK API Call: groups.getById (ids: ${idsString.substring(0, min(idsString.length, 100))}...)"); // Log truncated IDs
      final response = await _dio.get('groups.getById', queryParameters: {
        'group_ids': idsString,
        'access_token': vkToken,
        'fields': 'members_count,photo_50,photo_100,photo_200,screen_name,type',
        'v': _apiVersion,
      });
      final responseData = _handleResponse(response);

      // Handle potential difference in response structure (might be just 'response' or have 'groups' key)
      List<dynamic> groupsList = [];
      if (responseData is List) {
        // Direct list response
        groupsList = responseData;
      } else if (responseData is Map && responseData['groups'] is List) {
        // Nested under 'groups' key (seen in some API versions/contexts)
        groupsList = responseData['groups'];
      } else if (responseData is Map && responseData['response'] is List) {
        // Sometimes nested under 'response' ? (Less common for this method)
        groupsList = responseData['response'];
      }
      else {
        print("Warning: groups.getById response data is not a list or expected map structure.");
        return [];
      }

      return groupsList
          .map((groupData) => VKGroupInfo.fromJson(groupData as Map<String, dynamic>))
          .toList();

    } on DioException catch (e) {
      print("DioError fetching group details: ${e.message}");
      if (e.response != null) { print("DioError Response Data: ${e.response?.data}"); }
      return []; // Return empty list on error
    } catch (e, stackTrace) {
      print("Error parsing group details: $e\n$stackTrace");
      return []; // Return empty list on error
    }
  }
// --- END: NEW API METHODS ---

}

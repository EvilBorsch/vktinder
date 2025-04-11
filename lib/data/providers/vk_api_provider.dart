// lib/data/providers/vk_api_provider.dart
import 'dart:convert'; // Needed for mock data if used
import 'dart:math'; // For random numbers in mocks
import 'dart:async'; // For Future.delayed

import 'package:dio/dio.dart';
import 'package:flutter/material.dart'; // Needed for Colors in _handleResponse snackbar
import 'package:get/get.dart' as getx; // Use alias to avoid conflict with Get package's Get class
import 'package:vktinder/data/models/vk_group_user.dart';
import 'package:vktinder/data/models/vk_group_info.dart';

class VkApiProvider extends getx.GetxService {
  // --- START: MOCK DATA SWITCH ---
  /// Set to true to use local mock data instead of real VK API calls.
  static const bool _useMockData = false; // <-- CHANGE THIS FLAG
  // --- END: MOCK DATA SWITCH ---

  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://api.vk.com/method/',
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    queryParameters: {
      'v': '5.199',
    },
  ));
  final String _apiVersion = '5.199';

  // Helper to handle VK API errors (keep existing)
  dynamic _handleResponse(Response response) {
    if (response.statusCode == 200 && response.data != null) {
      if (response.data['error'] != null) {
        final error = response.data['error'];
        final errorMessage = error['error_msg'] ?? 'Unknown VK API error';
        final errorCode = error['error_code'] ?? -1;

        // Specific error handling can be added here (e.g., privacy, invalid params)
        print('VK API Error Response [$errorCode]: $errorMessage');
        // Handle common errors users might encounter
        if (errorCode == 5) { // Authorization failed (bad token)
          throw DioException(
            requestOptions: response.requestOptions,
            response: response,
            error: 'Ошибка авторизации [5]: Неверный VK токен. Проверьте токен в настройках.',
            type: DioExceptionType.unknown,
          );
        } else if (errorCode == 15 || errorCode == 30) { // Access denied / Private profile
          // Often okay for individual calls like getSubscriptions, but might indicate issues for search
          print('VK API Privacy Error [$errorCode]: ${error['error_msg']}');
          // Re-throw as a custom exception or specific DioException if needed
          // For now, just let the generic handler below catch it if not handled upstream
        } else if (errorCode == 100) { // One of the parameters specified was missing or invalid
          throw DioException(
            requestOptions: response.requestOptions,
            response: response,
            error: 'Ошибка параметров [100]: $errorMessage. Возможно, указан неверный ID группы или города.',
            type: DioExceptionType.unknown,
          );
        } else if (errorCode == 6) { // Too many requests per second
          print('VK API Rate Limit Error [6]: $errorMessage');
          throw DioException(
            requestOptions: response.requestOptions,
            response: response,
            error: 'Слишком много запросов [6]. Пожалуйста, подождите и попробуйте снова.',
            type: DioExceptionType.unknown,
          );
        }


        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Ошибка VK API [$errorCode]: $errorMessage',
          type: DioExceptionType.unknown,
        );
      }
      if (response.data is Map && response.data.containsKey('response')) {
        return response.data['response'];
      } else {
        print('VK API Success Response (no "response" key or not a map): ${response.data}');
        return response.data; // Return data even if 'response' key is missing (e.g., for boolean results)
      }
    } else {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: 'Ошибка сети при запросе к VK API (Статус: ${response.statusCode})',
        type: DioExceptionType.badResponse,
      );
    }
  }

  // --- Mock Data Section ---

  // Mock for getGroupUsers (used by old logic, maybe keep for testing)
  Future<List<VKGroupUser>> _getMockGroupUsers() async {
    print("[MOCK] Getting mock group users");
    await Future.delayed(const Duration(milliseconds: 500));
    return List.generate(15, (index) => VKGroupUser.fromJson({
      "id": 1000 + index,
      "first_name": "MockGroup",
      "last_name": "User$index",
      "photo_100": "https://via.placeholder.com/100/${Random().nextInt(0xFFFFFF).toRadixString(16)}/FFF?text=G${1000+index}",
      "photo_200": "https://via.placeholder.com/200/${Random().nextInt(0xFFFFFF).toRadixString(16)}/FFF?text=G${1000+index}",
      "sex": 1,
      "online": Random().nextInt(2),
      "city": {"id": 1, "title": "MockCity"},
    }));
  }

  // Mock for getFullProfile (returns base info, repo adds photos/groups)
  Future<VKGroupUser> _getMockFullProfile(String userID) async {
    print("[MOCK] Getting mock full profile for user ID: $userID");
    await Future.delayed(const Duration(milliseconds: 300));
    final id = int.tryParse(userID) ?? Random().nextInt(50000);
    return VKGroupUser.fromJson({
      "id": id,
      "first_name": "MockFull",
      "last_name": "Profile$id",
      "photo_100": "https://via.placeholder.com/100/${Random().nextInt(0xFFFFFF).toRadixString(16)}/FFF?text=F$id",
      "photo_200": "https://via.placeholder.com/200/${Random().nextInt(0xFFFFFF).toRadixString(16)}/FFF?text=F$id",
      "photo_max_orig":"https://via.placeholder.com/600/${Random().nextInt(0xFFFFFF).toRadixString(16)}/FFF?text=F$id",
      "sex": 1,
      "online": Random().nextInt(2),
      "screen_name": "mock_user_$id",
      "bdate": "15.5.1995",
      "city": {"id": 147, "title": "Севастополь"},
      "country": {"id": 1, "title": "Россия"},
      "interests": "Flutter, Dart, Mock Data, Cats",
      "about": "Это моковый профиль пользователя для тестирования.",
      "status": "Тестирую приложение \u{1F680}", // Rocket emoji
      "relation": 1, // single
      "last_seen": { "time": DateTime.now().millisecondsSinceEpoch ~/ 1000 - Random().nextInt(3600), "platform": 7 },
    });
  }

  // Mock for getUserPhotos
  Future<List<String>> _getMockUserPhotos(String userID) async {
    print("[MOCK] Getting mock photos for user ID: $userID");
    await Future.delayed(const Duration(milliseconds: 400));
    final id = int.tryParse(userID) ?? Random().nextInt(50000);
    return List.generate(Random().nextInt(5) + 1, // 1 to 5 photos
            (index) => "https://via.placeholder.com/600/${Random().nextInt(0xFFFFFF).toRadixString(16)}/FFF?text=Photo${index}_User$id"
    );
  }

  // Mock for sendMessage
  Future<bool> _sendMockMessage(String userId, String message) async {
    print("[MOCK] Sending message to user ID: $userId | Message: '$message'");
    await Future.delayed(const Duration(milliseconds: 600));
    // Simulate potential failure randomly
    final success = Random().nextDouble() > 0.1; // 90% success rate
    print("[MOCK] Send message result: $success");
    if (!success) {
      // Simulate a privacy error snackbar like the real implementation might do
      getx.Get.snackbar(
        'Mock Send Error',
        'Mock user $userId has privacy settings blocking messages.',
        snackPosition: getx.SnackPosition.BOTTOM, backgroundColor: Colors.orange[100], colorText: Colors.orange[900], margin: const EdgeInsets.all(8), borderRadius: 10, duration: const Duration(seconds: 4),
      );
    }
    return success;
  }

  // Mock for getUserSubscriptionIds
  Future<List<int>> _getMockUserSubscriptionIds(String userId) async {
    print("[MOCK] Getting mock subscription IDs for user ID: $userId");
    await Future.delayed(const Duration(milliseconds: 350));
    return List.generate(Random().nextInt(15) + 5, // 5 to 19 groups
            (index) => Random().nextInt(1000000) + 1 // Random group IDs
    );
  }


  // Mock for getGroupsById
  Future<List<VKGroupInfo>> _getMockGroupsById(List<String> groupIds) async {
    print("[MOCK] Getting mock group info for IDs: ${groupIds.join(',')}");
    await Future.delayed(const Duration(milliseconds: 450));
    List<VKGroupInfo> mockGroups = [];
    for (String idStr in groupIds) {
      final id = int.tryParse(idStr) ?? Random().nextInt(100000);
      mockGroups.add(VKGroupInfo.fromJson({
        "id": id,
        "name": "Mock Group $id",
        "screen_name": "mock_group_$id",
        "photo_50": "https://via.placeholder.com/50/AAA/FFF?text=G$id",
        "photo_100": "https://via.placeholder.com/100/AAA/FFF?text=G$id",
        "photo_200": "https://via.placeholder.com/200/AAA/FFF?text=G$id",
        "members_count": Random().nextInt(50000) + 100,
        "type": Random().nextBool() ? "group" : "page",
      }));
    }
    return mockGroups;
  }


  // Example Mock data for getGroupIdByScreenName
  Future<int?> _getMockGroupIdByScreenName(String screenName) async {
    print("[MOCK] Resolving screen name: $screenName");
    await Future.delayed(const Duration(milliseconds: 100));
    switch (screenName.toLowerCase()) { // case-insensitive mock
      case "flutterdev": return 1;
      case "facts": return 2;
      case "travel_club": return 3;
      case "cat_lovers": return 5;
      case "it_news": return 6;
      case "kino": return 7;
      case "recipes_vk": return 10;
      case "team": return 25504844; // Example: VK Team group
      case "durov": return 1; // Pavel Durov (as group/page)
      case "designhunters": return Random().nextInt(100000) + 10000;
      case "invalid_name": return null; // Simulate not found
      default:
      // Simulate finding some others, but not all
        if(screenName.hashCode % 3 != 0) {
          return Random().nextInt(100000) + 10000; // Random ID for others
        } else {
          return null; // Simulate not found for some inputs
        }
    }
  }

  // Example Mock data for getCitiesByName
  Future<List<Map<String, dynamic>>> _getMockCitiesByName(List<String> cityNames) async {
    print("[MOCK] Resolving city names: ${cityNames.join(', ')}");
    await Future.delayed(Duration(milliseconds: 150));
    final results = <Map<String, dynamic>>[];
    final predefinedCities = {
      "москва": {"id": 1, "title": "Москва"},
      "севастополь": {"id": 147, "title": "Севастополь"},
      "ялта": {"id": 1000, "title": "Ялта"}, // Made up ID
      "санкт-петербург": {"id": 2, "title": "Санкт-Петербург"},
      "питер": {"id": 2, "title": "Санкт-Петербург"}, // Alias
      "новгород": {"id": 95, "title": "Великий Новгород"}, // Example where input might be ambiguous
      "нижний новгород": {"id": 99, "title": "Нижний Новгород"},
    };
    for (var name in cityNames) {
      final lowerName = name.toLowerCase().trim();
      if (predefinedCities.containsKey(lowerName)) {
        results.add({"id": predefinedCities[lowerName]!['id'], "title": predefinedCities[lowerName]!['title']});
        // To simulate finding multiple, we could add more logic here,
        // but for simplicity, we return the first match.
      } else if (lowerName.isNotEmpty && lowerName.hashCode % 4 != 0) {
        // Simulate finding some other cities
        final mockId = Random().nextInt(5000) + 200;
        results.add({"id": mockId, "title": name.trim()}); // Use original casing for display?
      } else {
        print("[MOCK] City not found: $name");
      }
    }
    return results;
  }


  // Example Mock data for searchUsers
  Future<List<VKGroupUser>> _getMockSearchUsers({
    int? groupId,
    int? cityId,
    int? ageFrom,
    int? ageTo,
    int sex = 1, // Respect sex parameter
    int count = 20,
    int offset = 0
  }) async {
    print("[MOCK] Searching users: groupId=$groupId, cityId=$cityId, ageFrom=$ageFrom, ageTo=$ageTo, sex=$sex, count=$count, offset=$offset");
    await Future.delayed(const Duration(milliseconds: 700));

    if (offset >= 100) { // Simulate reaching the end of mock results
      print("[MOCK] Search yields no more results at offset $offset");
      return [];
    }

    // Generate some mock users based on filters
    List<VKGroupUser> mockUsers = [];
    final random = Random(groupId ?? 0 + cityId! ?? 0 + offset); // Seeded random for consistency per page
    for (int i = 0; i < count; i++) {
      final uniqueIdBase = (groupId ?? 0) * 10000 + (cityId ?? 0) * 100 + offset + i;
      final uniqueId = random.nextInt(900000) + uniqueIdBase; // Add randomness

      // Simulate filter matching (loosely)
      bool matchesCity = cityId == null || (uniqueId % 5 == cityId % 5); // Simulate city match rate
      int mockAge = 18 + random.nextInt(30); // Age 18-47
      bool matchesAge = (ageFrom == null || mockAge >= ageFrom) && (ageTo == null || mockAge <= ageTo);
      bool matchesSex = sex == (uniqueId % 3 == 1 ? 1 : 2); // Simulate ~1/3 female, 2/3 male if sex=0

      if (matchesCity && matchesAge && matchesSex) {
        mockUsers.add(VKGroupUser.fromJson({ // Using simplified structure for mock
          "id": uniqueId,
          "first_name": "Поиск${groupId ?? 'G'}${cityId ?? 'C'}",
          "last_name": "Юзер${offset + i}",
          "photo_100": "https://via.placeholder.com/100/${uniqueId % 2 == 0 ? '00F' : 'F00'}/FFF?text=S$uniqueId",
          "photo_200": "https://via.placeholder.com/200/${uniqueId % 2 == 0 ? '00F' : 'F00'}/FFF?text=S$uniqueId",
          "sex": sex, // Return the requested sex
          "online": random.nextInt(2),
          "bdate": "1.1.${DateTime.now().year - mockAge}", // Approximate bdate
          "city": cityId != null ? {"id": cityId, "title": "Город $cityId"} : null,
          "last_seen": { "time": DateTime.now().millisecondsSinceEpoch ~/ 1000 - random.nextInt(3600*24), "platform": 7 },
          "screen_name": "search_user_$uniqueId",
        }));
      }
    }
    print("[MOCK] Found ${mockUsers.length} mock users for search.");
    return mockUsers;
  }

  // --- End Mock Data Section ---


  // --- Existing API Methods (Implementations using _handleResponse, etc.) ---

  Future<List<VKGroupUser>> getGroupUsers(String vkToken, String groupId) async {
    // --- MOCK SWITCH ---
    if (_useMockData) return _getMockGroupUsers(); // <--- Corrected Call
    // --- END MOCK SWITCH ---

    if (vkToken.isEmpty || groupId.isEmpty) {
      print("Error: VK Token or Group ID is missing for getGroupUsers.");
      throw ArgumentError('VK Token and Group ID must be provided.');
    }
    // ... (rest of the method remains the same)
    try {
      print("VK API Call: groups.getMembers (groupId: $groupId)");
      final response = await _dio.get(
        'groups.getMembers',
        queryParameters: {
          'group_id': groupId,
          'access_token': vkToken,
          'fields': 'id,first_name,last_name,photo_100,photo_200,sex,online,city,country,bdate',
          'v': _apiVersion,
          'count': 1000,
        },
      );
      final responseData = _handleResponse(response);
      if (responseData == null || responseData['items'] == null) {
        print("Warning: groups.getMembers response data or items list is null.");
        return [];
      }
      final List usersList = responseData['items'] ?? [];
      return usersList
          .where((userData) => (userData['sex'] ?? 0) == 1)
          .map((userData) => VKGroupUser.fromJson(userData as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      print("DioError fetching group users: ${e.message}");
      throw Exception('Не удалось загрузить участников группы: ${e.message?.split(':').last.trim() ?? 'Ошибка сети'}');
    } catch (e, stackTrace) {
      print("Error parsing group users: $e\n$stackTrace");
      throw Exception('Не удалось обработать данные участников группы.');
    }
  }


  Future<VKGroupUser> getFullProfile(String vkToken, String userID) async {
    // --- MOCK SWITCH ---
    if (_useMockData) {
      // MOCK: Needs to be modified in the repository to also call mock group methods
      return _getMockFullProfile(userID); // <--- Corrected Call
    }
    // --- END MOCK SWITCH ---
    // ... (rest of the method remains the same)
    if (vkToken.isEmpty || userID.isEmpty) {
      throw ArgumentError("VK Token and User ID must be provided for getFullProfile.");
    }
    try {
      print("VK API Call: users.get (userId: $userID)");
      final response = await _dio.get('users.get', queryParameters: {
        'user_ids': userID,
        'fields': 'id,first_name,last_name,photo_max_orig,sex,bdate,city,country,interests,about,status,relation,screen_name,online,last_seen,photo_50,photo_100,photo_200,photo_400_orig',
        'access_token': vkToken,
        'v': _apiVersion,
      });
      final responseData = _handleResponse(response);
      if (responseData == null || responseData is! List || responseData.isEmpty) {
        print("Warning: users.get response data is null, not a list, or empty.");
        throw Exception('Профиль пользователя не найден или ошибка API.');
      }
      final user = VKGroupUser.fromJson(responseData[0] as Map<String, dynamic>);
      return user;

    } on DioException catch (e) {
      print("DioError fetching full profile: ${e.message}");
      if (e.response?.data?['error']?['error_code'] == 15 || e.response?.data?['error']?['error_code'] == 30) {
        throw Exception('Не удалось загрузить профиль: Доступ к профилю ограничен.');
      }
      throw Exception('Не удалось загрузить профиль: ${e.message?.split(':').last.trim() ?? 'Ошибка сети'}');
    } catch (e, stackTrace) {
      print("Error parsing profile: $e\n$stackTrace");
      throw Exception('Не удалось обработать данные профиля.');
    }
  }


  Future<List<String>> getUserPhotos(String vkToken, String userID) async {
    // --- MOCK SWITCH ---
    if (_useMockData) {
      return _getMockUserPhotos(userID); // <--- Corrected Call
    }
    // --- END MOCK SWITCH ---
    // ... (rest of the method remains the same)
    if (vkToken.isEmpty || userID.isEmpty) {
      print("Warning: VK Token or User ID missing for getUserPhotos. Returning empty list.");
      return []; // Don't throw, just return empty
    }
    try {
      print("VK API Call: photos.get (ownerId: $userID)");
      final response = await _dio.get('photos.get', queryParameters: {
        'owner_id': userID,
        'album_id': 'profile',
        'access_token': vkToken,
        'extended': 1,
        'photo_sizes': 1,
        'count': 30,
        'v': _apiVersion,
      });
      final responseData = _handleResponse(response);
      if (responseData == null || responseData['items'] == null) {
        print("Warning: photos.get response data or items list is null for user $userID.");
        return [];
      }
      final List photosList = responseData['items'] ?? [];
      photosList.sort((a, b) => (b['likes']?['count'] ?? 0).compareTo(a['likes']?['count'] ?? 0));

      return photosList.map((photoData) {
        if (photoData == null || photoData['sizes'] == null) return null;
        final sizes = (photoData['sizes'] as List?) ?? [];
        if (sizes.isNotEmpty) {
          final priority = ['w', 'z', 'y', 'x', 'r', 'q', 'p', 'o', 'm', 's'];
          for (String type in priority) {
            try {
              final size = sizes.lastWhere((s) => s != null && s['type'] == type, orElse: () => null);
              if (size != null && size['url'] is String) return size['url'] as String;
            } catch (e) { print("Error finding photo size '$type': $e"); }
          }
          try {
            if (sizes.last != null && sizes.last['url'] is String) return sizes.last['url'] as String;
          } catch (e) { print("Error accessing last photo size: $e"); }
        }
        return null;
      }).whereType<String>().toList();

    } on DioException catch (e) {
      if (e.response?.data?['error']?['error_code'] == 15 || e.response?.data?['error']?['error_code'] == 200 || e.response?.data?['error']?['error_code'] == 30) {
        print("Could not fetch photos for user $userID due to privacy settings or access error.");
      } else {
        print("DioError fetching user photos for $userID: ${e.message}");
        if (e.response != null) { print("DioError Response Data: ${e.response?.data}"); }
      }
      return [];
    } catch (e, stackTrace) {
      print("Error parsing photos for user $userID: $e\n$stackTrace");
      return [];
    }
  }


  Future<bool> sendMessage(String vkToken, String userId, String message) async {
    // --- MOCK SWITCH ---
    if (_useMockData) return _sendMockMessage(userId, message); // <--- Corrected Call
    // --- END MOCK SWITCH ---
    // ... (rest of the method remains the same)
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
      if (response.data != null && response.data['error'] != null) {
        final error = response.data['error'];
        final errorCode = error['error_code'] ?? -1;
        final errorMessage = error['error_msg'] ?? 'Unknown VK send message error';
        print('VK API Send Error Response [$errorCode]: $errorMessage');

        if (errorCode == 900 || errorCode == 901 || errorCode == 902) {
          getx.Get.snackbar( // Use alias here
            'Ошибка отправки',
            'Невозможно отправить сообщение этому пользователю из-за настроек приватности.',
            snackPosition: getx.SnackPosition.BOTTOM, backgroundColor: Colors.orange[100], colorText: Colors.orange[900], margin: const EdgeInsets.all(8), borderRadius: 10, duration: const Duration(seconds: 4),
          );
          return false;
        }
        if (errorCode == 7) {
          getx.Get.snackbar( // Use alias here
            'Ошибка прав доступа',
            'У вашего токена нет прав на отправку сообщений.',
            snackPosition: getx.SnackPosition.BOTTOM, backgroundColor: Colors.red[100], colorText: Colors.red[900], margin: const EdgeInsets.all(8), borderRadius: 10, duration: const Duration(seconds: 4),
          );
          return false;
        }
      }
      final responseData = _handleResponse(response);
      if (responseData != null && responseData is int) {
        print("Message sent successfully, message ID: $responseData");
        return true;
      } else {
        print("Message send call succeeded, but response was not the expected message ID: $responseData");
        getx.Get.snackbar( // Use alias here
          'Ошибка',
          'Не удалось отправить сообщение (неожиданный ответ).',
          snackPosition: getx.SnackPosition.BOTTOM, backgroundColor: Colors.red[100], colorText: Colors.red[900], margin: const EdgeInsets.all(8), borderRadius: 10, duration: const Duration(seconds: 3),
        );
        return false;
      }
    } on DioException catch (e) {
      print("DioError sending message: ${e.error}");
      getx.Get.snackbar( // Use alias here
        'Ошибка сети',
        'Не удалось отправить сообщение: ${e.error ?? 'Проверьте соединение.'}',
        snackPosition: getx.SnackPosition.BOTTOM, backgroundColor: Colors.red[100], colorText: Colors.red[900], margin: const EdgeInsets.all(8), borderRadius: 10, duration: const Duration(seconds: 3),
      );
      return false;
    } catch (e, stackTrace) {
      print("Generic error sending message: $e\n$stackTrace");
      getx.Get.snackbar( // Use alias here
        'Неизвестная ошибка',
        'Произошла ошибка при отправке сообщения.',
        snackPosition: getx.SnackPosition.BOTTOM, backgroundColor: Colors.red[100], colorText: Colors.red[900], margin: const EdgeInsets.all(8), borderRadius: 10, duration: const Duration(seconds: 3),
      );
      return false;
    }
  }


  Future<List<int>> getUserSubscriptionIds(String vkToken, String userId) async {
    // --- MOCK SWITCH ---
    if (_useMockData) return _getMockUserSubscriptionIds(userId); // <--- Corrected Call
    // --- END MOCK SWITCH ---
    // ... (rest of the method remains the same)
    if (vkToken.isEmpty || userId.isEmpty) {
      print("Error: VK Token or User ID is missing for getUserSubscriptions.");
      return [];
    }
    try {
      print("VK API Call: users.getSubscriptions (userId: $userId)");
      final response = await _dio.get('users.getSubscriptions', queryParameters: {
        'user_id': userId,
        'extended': 0,
        'access_token': vkToken,
        'v': _apiVersion,
        'count': 200
      });
      final responseData = _handleResponse(response);
      if (responseData?['groups']?['items'] is List) {
        final List groupIdsRaw = responseData['groups']['items'];
        final List<int> groupIds = groupIdsRaw.map((id) => id as int).where((id) => id > 0).toList();
        print("Fetched ${groupIds.length} group subscription IDs for user $userId.");
        return groupIds;
      } else {
        print("Warning: users.getSubscriptions response did not contain a valid groups list for user $userId.");
        return [];
      }
    } on DioException catch (e) {
      if (e.response?.data?['error']?['error_code'] == 15 || e.response?.data?['error']?['error_code'] == 30) {
        print("Could not fetch subscriptions for user $userId due to privacy settings.");
      } else {
        print("DioError fetching user subscriptions for $userId: ${e.message}");
        if (e.response != null) { print("DioError Response Data: ${e.response?.data}"); }
      }
      return [];
    } catch (e, stackTrace) {
      print("Error parsing user subscriptions for $userId: $e\n$stackTrace");
      return [];
    }
  }


  Future<List<VKGroupInfo>> getGroupsById(String vkToken, List<String> groupIds) async {
    // --- MOCK SWITCH ---
    if (_useMockData) return _getMockGroupsById(groupIds); // <--- Corrected Call
    // --- END MOCK SWITCH ---
    // ... (rest of the method remains the same)
    if (vkToken.isEmpty || groupIds.isEmpty) {
      return [];
    }
    List<VKGroupInfo> allGroups = [];
    const chunkSize = 450;

    for (var i = 0; i < groupIds.length; i += chunkSize) {
      final chunk = groupIds.sublist(i, min(i + chunkSize, groupIds.length));
      final idsString = chunk.join(',');

      try {
        print("VK API Call: groups.getById (chunk ${i ~/ chunkSize + 1}, ${chunk.length} IDs)");
        final response = await _dio.get('groups.getById', queryParameters: {
          'group_ids': idsString,
          'access_token': vkToken,
          'fields': 'members_count,photo_50,photo_100,photo_200,screen_name,type',
          'v': _apiVersion,
        });
        final responseData = _handleResponse(response);

        List<dynamic> groupsList = [];
        if (responseData is List) {
          groupsList = responseData;
        } else if (responseData is Map && responseData.containsKey('groups') && responseData['groups'] is List) {
          groupsList = responseData['groups'];
        } else {
          print("Warning: groups.getById response data is not a list or expected map structure for chunk ${i ~/ chunkSize + 1}. Response: $responseData");
          continue;
        }

        allGroups.addAll(groupsList
            .map((groupData) => VKGroupInfo.fromJson(groupData as Map<String, dynamic>))
            .toList());

      } on DioException catch (e) {
        print("DioError fetching group details chunk ${i ~/ chunkSize + 1}: ${e.message}");
        if (e.response != null) { print("DioError Response Data: ${e.response?.data}"); }
      } catch (e, stackTrace) {
        print("Error parsing group details chunk ${i ~/ chunkSize + 1}: $e\n$stackTrace");
      }
      if (groupIds.length > chunkSize && i + chunkSize < groupIds.length) {
        await Future.delayed(const Duration(milliseconds: 350));
      }
    }
    print("Fetched details for ${allGroups.length} groups out of ${groupIds.length} requested.");
    return allGroups;
  }


  // --- START: NEW API METHODS FOR SEARCH ---

  Future<VKGroupInfo?> getGroupInfoByScreenName(String vkToken, String screenNameOrUrl) async {
    // --- MOCK SWITCH ---
    if (_useMockData) {
      final mockId = await _getMockGroupIdByScreenName(_extractScreenName(screenNameOrUrl));
      if (mockId != null) {
        // Return a basic mock VKGroupInfo
        return VKGroupInfo(
            id: mockId,
            name: "Mock Group $mockId",
            screenName: _extractScreenName(screenNameOrUrl),
            type: 'group', // default type
            sourceUrl: screenNameOrUrl,
            photo100: "https://via.placeholder.com/100/888/FFF?text=G$mockId"
        );
      }
      return null;
    }
    // --- END MOCK SWITCH ---
    // ... (rest of the method remains the same)
    if (vkToken.isEmpty || screenNameOrUrl.isEmpty) {
      print("Error: VK Token or screenName/URL is missing for getGroupInfoByScreenName.");
      return null;
    }

    final screenName = _extractScreenName(screenNameOrUrl);
    if (screenName.isEmpty) {
      print("Error: Could not extract valid screen name from '$screenNameOrUrl'.");
      return null;
    }

    try {
      print("VK API Call: groups.getById (resolving screen_name: $screenName)");
      final response = await _dio.get('groups.getById', queryParameters: {
        'group_id': screenName,
        'access_token': vkToken,
        'fields': 'members_count,photo_50,photo_100,photo_200,screen_name,type',
        'v': _apiVersion,
      });
      final responseData = _handleResponse(response);

      if (responseData is List && responseData.isNotEmpty) {
        final groupData = responseData[0] as Map<String, dynamic>;
        return VKGroupInfo.fromJson(groupData, sourceUrl: screenNameOrUrl);
      } else if (responseData is Map && responseData.containsKey('groups') && responseData['groups'] is List && responseData['groups'].isNotEmpty) {
        final groupData = responseData['groups'][0] as Map<String, dynamic>;
        return VKGroupInfo.fromJson(groupData, sourceUrl: screenNameOrUrl);
      }
      else {
        print("Group with screen_name '$screenName' not found or API response format unexpected.");
        return null;
      }
    } on DioException catch (e) {
      print("DioError resolving group screen name '$screenName': ${e.message}");
      if (e.response != null) { print("DioError Response Data: ${e.response?.data}"); }
      return null;
    } catch (e, stackTrace) {
      print("Error parsing group info for screen name '$screenName': $e\n$stackTrace");
      return null;
    }
  }


  String _extractScreenName(String input) {
    input = input.trim();
    if (input.isEmpty) return '';
    Uri? uri = Uri.tryParse(input);
    if (uri != null && (uri.host.contains('vk.com') || uri.host.contains('vkontakte.ru'))) {
      if (uri.pathSegments.isNotEmpty) {
        return uri.pathSegments.last;
      }
    }
    if (input.startsWith('@')) input = input.substring(1);
    if (input.startsWith('/')) input = input.substring(1);
    if (RegExp(r'^[a-zA-Z0-9_.]+$').hasMatch(input)) {
      return input;
    }
    print("Warning: Input '$input' doesn't look like a valid VK URL or screen name.");
    return '';
  }


  Future<Map<String, int>> getCityIdsByNames(String vkToken, List<String> cityNames) async {
    // --- MOCK SWITCH ---
    if (_useMockData) {
      final mockCities = await _getMockCitiesByName(cityNames);
      // Return map key as lowercase input name, value as found ID
      final Map<String, int> resultMap = {};
      final mockMap = { for (var city in mockCities) city['title'].toString().toLowerCase(): city['id'] as int }; // Map found titles to IDs
      for (var inputName in cityNames) {
        final lowerInput = inputName.toLowerCase().trim();
        // Find if any mock result matches the input name (handling aliases)
        for (var mockEntry in mockCities) {
          // Basic check: if mock title contains input name (simplistic) or if predefined maps it
          final lowerMockTitle = mockEntry['title'].toString().toLowerCase();
          if (lowerMockTitle.contains(lowerInput) ||
              (lowerInput == "питер" && mockEntry['id'] == 2) || // Handle specific aliases used in mock
              (predefinedCities[lowerInput]?['id'] == mockEntry['id'] ) //Check pre-defined map as well
          ){
            resultMap[inputName.trim()] = mockEntry['id'] as int; // Use original case
            break; // Take first match for this input name
          }
        }
      }
      print("[MOCK] Resolved city names to IDs: $resultMap");
      return resultMap;
    }
    // --- END MOCK SWITCH ---
    // ... (rest of the method remains the same)
    if (vkToken.isEmpty || cityNames.isEmpty) {
      return {};
    }

    Map<String, int> cityIdMap = {};
    final uniqueLowerTrimmedNames = cityNames.map((n) => n.toLowerCase().trim()).where((n) => n.isNotEmpty).toSet(); // Process unique non-empty names

    for (String lowerTrimmedCityName in uniqueLowerTrimmedNames) {
      if (cityIdMap.containsKey(lowerTrimmedCityName)) continue;

      try {
        print("VK API Call: database.getCities (query: $lowerTrimmedCityName)");
        final response = await _dio.get('database.getCities', queryParameters: {
          'country_id': 1,
          'q': lowerTrimmedCityName,
          'need_all': 0,
          'count': 1,
          'access_token': vkToken,
          'v': _apiVersion,
        });
        final responseData = _handleResponse(response);

        if (responseData != null && responseData['items'] is List && responseData['items'].isNotEmpty) {
          final cityInfo = responseData['items'][0] as Map<String, dynamic>;
          final cityId = cityInfo['id'] as int?;
          final foundTitle = cityInfo['title'] as String?;
          if (cityId != null && foundTitle != null) {
            print("Resolved city '$lowerTrimmedCityName' (found as '$foundTitle') to ID: $cityId");
            cityIdMap[lowerTrimmedCityName] = cityId;
          } else {
            print("Warning: City '$lowerTrimmedCityName' found but has null ID or title.");
          }
        } else {
          print("Warning: City '$lowerTrimmedCityName' not found via VK API.");
        }
      } on DioException catch (e) {
        print("DioError getting city ID for '$lowerTrimmedCityName': ${e.message}");
      } catch (e, stackTrace) {
        print("Error parsing city response for '$lowerTrimmedCityName': $e\n$stackTrace");
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }
    // Now map the results back to the original input names (case-insensitive)
    Map<String, int> finalResultMap = {};
    for (String originalName in cityNames) {
      final key = originalName.toLowerCase().trim();
      if (cityIdMap.containsKey(key)) {
        finalResultMap[originalName.trim()] = cityIdMap[key]!; // Use original name as key to preserve case
      }
    }
    print("Resolved ${finalResultMap.length} cities out of ${cityNames.length} requested names.");
    return finalResultMap;
  }



  Future<List<VKGroupUser>> searchUsers({
    required String vkToken,
    int? groupId,
    int? cityId,
    int? ageFrom,
    int? ageTo,
    int sex = 1,
    int count = 100,
    int offset = 0,
  }) async {
    // --- MOCK SWITCH ---
    if (_useMockData) {
      return _getMockSearchUsers(groupId: groupId, cityId: cityId, ageFrom: ageFrom, ageTo: ageTo, sex: sex, count: count, offset: offset); // <--- Pass sex=sex
    }
    // --- END MOCK SWITCH ---
    // ... (rest of the method remains the same)
    if (vkToken.isEmpty) {
      throw ArgumentError("VK Token must be provided for searchUsers.");
    }

    final Map<String, dynamic> queryParams = {
      'access_token': vkToken,
      'v': _apiVersion,
      'count': count.clamp(1, 1000),
      'offset': offset,
      'sex': sex,
      'fields': 'id,first_name,last_name,photo_100,photo_200,online,city,country,bdate,screen_name,last_seen,can_write_private_message',
    };

    if (groupId != null) queryParams['group_id'] = groupId;
    if (cityId != null) queryParams['city'] = cityId;
    if (ageFrom != null) queryParams['age_from'] = ageFrom;
    if (ageTo != null) queryParams['age_to'] = ageTo;

    try {
      print("VK API Call: users.search (params: ${queryParams.keys.where((k) => k!='access_token').join(',')}) Offset: $offset");
      final response = await _dio.get('users.search', queryParameters: queryParams);
      final responseData = _handleResponse(response);

      if (responseData == null || responseData['items'] == null) {
        print("Warning: users.search response data or items list is null.");
        return [];
      }
      final List usersList = responseData['items'] ?? [];
      print("users.search returned ${usersList.length} users (offset: $offset).");

      return usersList
          .where((userData) => userData['deactivated'] == null)
          .map((userData) => VKGroupUser.fromJson(userData as Map<String, dynamic>))
          .toList();

    } on DioException catch (e) {
      print("DioError searching users: ${e.message}");
      if (e.response != null) { print("DioError Response Data: ${e.response?.data}"); }
      if (e.response?.data?['error']?['error_code'] == 15 || e.response?.data?['error']?['error_code'] == 30) {
        throw Exception('Ошибка поиска: Доступ к некоторым данным ограничен приватностью.');
      }
      throw Exception('Ошибка поиска пользователей: ${e.message?.split(':').last.trim() ?? 'Ошибка сети'}');
    } catch (e, stackTrace) {
      print("Error parsing search results: $e\n$stackTrace");
      throw Exception('Не удалось обработать результаты поиска.');
    }
  }

  // Helper to get predefined cities for mock lookup
  Map<String, Map<String, dynamic>> get predefinedCities => {
    "москва": {"id": 1, "title": "Москва"},
    "севастополь": {"id": 147, "title": "Севастополь"},
    "ялта": {"id": 1000, "title": "Ялта"},
    "санкт-петербург": {"id": 2, "title": "Санкт-Петербург"},
    "питер": {"id": 2, "title": "Санкт-Петербург"},
    "новгород": {"id": 95, "title": "Великий Новгород"},
    "нижний новгород": {"id": 99, "title": "Нижний Новгород"},
  };


// --- END: NEW API METHODS ---
}

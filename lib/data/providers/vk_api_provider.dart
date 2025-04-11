import 'package:dio/dio.dart';
import 'package:get/get.dart' as getx;
import 'package:vktinder/data/models/vk_group_user.dart';
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
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
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
        final errorMessage = error['error_msg'] ?? 'Unknown VK API error';
        final errorCode = error['error_code'] ?? -1;
        print('VK API Error Response: ${response.data}');
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'VK API Error [$errorCode]: $errorMessage',
          type: DioExceptionType.unknown,
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

  // Mock data for getGroupUsers
  Future<List<VKGroupUser>> _getMockGroupUsers() async {
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

  // Mock data for getFullProfile
  Future<VKGroupUser> _getMockFullProfile(String userID) async {
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
      }
    };

    // Customize based on userID for variety
    switch(userID) {
      case "102":
        mockProfileBase["first_name"] = "Елена";
        mockProfileBase["last_name"] = "Пример";
        mockProfileBase["bdate"] = "23.11.1997";
        mockProfileBase["interests"] = "музыка, спорт, книги";
        mockProfileBase["status"] = "В поисках новых знакомств";
        mockProfileBase["relation"] = 6; // 6=actively searching
        mockProfileBase["city"] = {"id": 2, "title": "Санкт-Петербург"};
        mockProfileBase["about"] = "Люблю творчество и активный отдых. Играю на гитаре и пишу стихи.";
        mockProfileBase["online"] = 0;
        break;

      case "103":
        mockProfileBase["first_name"] = "Мария";
        mockProfileBase["last_name"] = "Разработкова";
        mockProfileBase["bdate"] = "7.2.1992";
        mockProfileBase["interests"] = "программирование, дизайн, фотография, путешествия";
        mockProfileBase["status"] = "Работаю над интересным проектом \uD83D\uDCBB";
        mockProfileBase["relation"] = 1; // 1=single
        mockProfileBase["city"] = {"id": 3, "title": "Казань"};
        mockProfileBase["about"] = "Frontend разработчик с опытом в дизайне. Увлекаюсь фотографией и походами.";
        break;

      case "104":
        mockProfileBase["first_name"] = "Александр";
        mockProfileBase["last_name"] = "Тестов";
        mockProfileBase["sex"] = 2; // male
        mockProfileBase["bdate"] = "14.9.1990";
        mockProfileBase["interests"] = "технологии, спорт, автомобили";
        mockProfileBase["status"] = "Всегда в движении";
        mockProfileBase["relation"] = 2; // 2=in relationship
        mockProfileBase["city"] = {"id": 4, "title": "Новосибирск"};
        mockProfileBase["about"] = "Инженер-программист. Люблю технические новинки и активный образ жизни.";
        mockProfileBase["online"] = 0;
        break;

      case "105":
        mockProfileBase["first_name"] = "Иван";
        mockProfileBase["last_name"] = "Примеров";
        mockProfileBase["sex"] = 2; // male
        mockProfileBase["bdate"] = "30.6.1988";
        mockProfileBase["interests"] = "история, туризм, фильмы, игры";
        mockProfileBase["status"] = "Ищу единомышленников для путешествий";
        mockProfileBase["relation"] = 1; // 1=single
        mockProfileBase["city"] = {"id": 5, "title": "Екатеринбург"};
        mockProfileBase["about"] = "Историк по образованию, программист по профессии. Увлекаюсь настольными играми и походами.";
        break;
    }

    // Update image URLs based on sex to have different placeholders
    final colorCode = mockProfileBase["sex"] == 1 ? "FF0000" : "0000FF"; // Red for female, Blue for male
    final baseUrl = "https://via.placeholder.com";

    mockProfileBase["photo_max_orig"] = "$baseUrl/800x600/$colorCode/FFFFFF?text=${mockProfileBase["first_name"]}_$userID";
    mockProfileBase["photo_400_orig"] = "$baseUrl/400x300/$colorCode/FFFFFF?text=${mockProfileBase["first_name"]}_$userID";
    mockProfileBase["photo_200"] = "$baseUrl/200/$colorCode/FFFFFF?text=${mockProfileBase["first_name"]}_$userID";
    mockProfileBase["photo_100"] = "$baseUrl/100/$colorCode/FFFFFF?text=${mockProfileBase["first_name"]}_$userID";

    return VKGroupUser.fromJson(mockProfileBase as Map<String, dynamic>);
  }

  // Mock data for getUserPhotos
  Future<List<String>> _getMockUserPhotos(String userID) async {
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

  // Mock data for sendMessage
  Future<bool> _sendMockMessage(String userId, String message) async {
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

  // --- API Methods with Mock Switch ---

  Future<List<VKGroupUser>> getGroupUsers(String vkToken, String groupId) async {
    // --- MOCK SWITCH ---
    if (_useMockData) {
      return _getMockGroupUsers();
    }
    // --- END MOCK SWITCH ---

    // Real API Call Logic (updated fields)
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
          'fields': 'id,first_name,last_name,photo_100,photo_200,sex,online',
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
      return _getMockFullProfile(userID);
    }
    // --- END MOCK SWITCH ---

    // Real API Call Logic (updated fields)
    if (vkToken.isEmpty || userID.isEmpty) {
      throw ArgumentError("VK Token and User ID must be provided for getFullProfile.");
    }
    try {
      print("VK API Call: users.get (userId: $userID)");
      final response = await _dio.get('users.get', queryParameters: {
        'user_ids': userID,
        'fields': 'id,first_name,last_name,photo_max_orig,sex,bdate,city,country,interests,about,status,relation,screen_name,online,last_seen,photo_200,photo_400_orig',
        'access_token': vkToken,
        'v': _apiVersion,
      });
      final responseData = _handleResponse(response);
      if (responseData == null || responseData is! List || responseData.isEmpty) {
        print("Warning: users.get response data is null, not a list, or empty.");
        throw Exception('User profile not found or API error.');
      }
      return VKGroupUser.fromJson(responseData[0] as Map<String, dynamic>);
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

    // Real API Call Logic (as before)
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
      throw Exception('Failed to load user photos: ${e.message}');
    } catch (e, stackTrace) {
      print("Error parsing photos: $e\n$stackTrace");
      throw Exception('Failed to parse user photos data.');
    }
  }

  Future<bool> sendMessage(String vkToken, String userId, String message) async {
    // --- MOCK SWITCH ---
    if (_useMockData) {
      return _sendMockMessage(userId, message);
    }
    // --- END MOCK SWITCH ---

    // Real API Call Logic (as before)
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
        print("Message send call succeeded, but response was not the expected message ID: $responseData");
        return false;
      }
    } on DioException catch (e) {
      print("DioError sending message: ${e.message}");
      if (e.response != null) { print("DioError Response Data: ${e.response?.data}"); }
      return false;
    } catch (e, stackTrace) {
      print("Error sending message: $e\n$stackTrace");
      return false;
    }
  }
}

import 'package:dio/dio.dart';
import 'package:dio/src/response.dart' as dioResponse;
import 'package:get/get.dart';
import 'package:vktinder/data/models/vk_group_user.dart';
import 'dart:math'; // For random_id

class VkApiProvider extends GetxService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://api.vk.com/method/',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    queryParameters: {
      'v': '5.199', // Specify a recent API version
    },
  ));

  // Helper to handle VK API errors
  dynamic _handleResponse(dioResponse.Response response) {
    if (response.statusCode == 200 && response.data != null) {
      if (response.data['error'] != null) {
        final error = response.data['error'];
        final errorMessage = error['error_msg'] ?? 'Unknown VK API error';
        final errorCode = error['error_code'] ?? -1;
        // You might want to throw more specific exceptions based on error_code
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'VK API Error [$errorCode]: $errorMessage',
          type: DioExceptionType.unknown,
        );
      }
      return response.data['response']; // Return only the 'response' part
    } else {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: 'Failed to communicate with VK API',
        type: DioExceptionType.badResponse,
      );
    }
  }


  /// Fetches members of a specific VK group.
  /// Requires a valid access token and the ID of the group.
  Future<List<VKGroupUser>> getGroupUsers(String vkToken, String groupId) async {
    if (vkToken.isEmpty || groupId.isEmpty) {
      // Return empty or throw error if essential info is missing
      print("Error: VK Token or Group ID is missing.");
      return [];
    }
    try {
      final response = await _dio.get(
        'groups.getMembers',
        queryParameters: {
          'group_id': groupId,
          'access_token': vkToken,
          'fields': 'id,first_name,last_name,photo_100', // Request necessary fields
          // Add other fields if needed for the card initially
        },
      );
      final responseData = _handleResponse(response);
      final List usersList = responseData['items'] ?? [];

      // Map the response items to your VKGroupUser model
      return usersList
          .map((userData) => VKGroupUser.fromJson(userData as Map<String, dynamic>))
          .toList();

    } on DioException catch (e) {
      print("DioError fetching group users: ${e.message}");
      print("Response data: ${e.response?.data}");
      // Re-throw or handle appropriately (e.g., return empty list, show error message)
      throw Exception('Failed to load group users: ${e.message}');
    } catch (e) {
      print("Error parsing group users: $e");
      throw Exception('Failed to parse group users data.');
    }
  }

  /// Fetches detailed profile information for a specific user.
  Future<VKGroupUser> getFullProfile(String vkToken, String userID) async {
    if (vkToken.isEmpty || userID.isEmpty) {
      throw Exception("VK Token or User ID is missing.");
    }
    try {
      final response = await _dio.get(
        'users.get',
        queryParameters: {
          'user_ids': userID,
          'fields': 'id,first_name,last_name,photo_max_orig,sex,bdate,city,country,interests,about,status,relation,screen_name', // Add comma-separated fields you need
          'access_token': vkToken,
        },
      );
      final responseData = _handleResponse(response);
      final List userList = responseData ?? [];

      if (userList.isEmpty) {
        throw Exception('User not found or API error.');
      }
      // users.get returns a list, even for one user
      return VKGroupUser.fromJson(userList[0] as Map<String, dynamic>);

    } on DioException catch (e) {
      print("DioError fetching full profile: ${e.message}");
      print("Response Data: ${e.response?.data}");
      throw Exception('Failed to load user profile: ${e.message}');
    } catch (e) {
      print("Error parsing profile: $e");
      throw Exception('Failed to parse user profile data.');
    }
  }

  /// Fetches photos from the user's profile album.
  Future<List<String>> getUserPhotos(String vkToken, String userID) async {
    if (vkToken.isEmpty || userID.isEmpty) {
      throw Exception("VK Token or User ID is missing.");
    }
    try {
      final response = await _dio.get(
        'photos.get',
        queryParameters: {
          'owner_id': userID,
          'album_id': 'profile', // Common album IDs: 'profile', 'wall', 'saved'
          'access_token': vkToken,
          'extended': 1, // Get photo URLs in different sizes
          'photo_sizes': 1, // Include sizes array
          'count': 20, // Limit number of photos
        },
      );

      final responseData = _handleResponse(response);
      final List photosList = responseData['items'] ?? [];

      // Extract the URL of the largest available photo size
      return photosList.map((photoData) {
        final sizes = (photoData['sizes'] as List?) ?? [];
        if (sizes.isNotEmpty) {
          // Find the largest size (usually 'w', 'z', 'y', 'x', 'm', 's' etc.)
          // Let's prioritize 'w', then 'z', 'y', 'x'
          final priority = ['w', 'z', 'y', 'x', 'm', 's'];
          for(String type in priority) {
            final size = sizes.firstWhere((s) => s['type'] == type, orElse: () => null);
            if (size != null) return size['url'] as String;
          }
          // Fallback to the last available size URL if specific types not found
          return sizes.last['url'] as String;
        }
        // Fallback placeholder or handle case with no sizes (shouldn't happen with photo_sizes=1)
        return 'https://vk.com/images/camera_200.png'; // Placeholder
      }).toList();

    } on DioException catch (e) {
      print("DioError fetching user photos: ${e.message}");
      print("Response Data: ${e.response?.data}");
      throw Exception('Failed to load user photos: ${e.message}');
    } catch (e) {
      print("Error parsing photos: $e");
      throw Exception('Failed to parse user photos data.');
    }
  }

  /// Sends a message to a specified user.
  /// Requires 'messages' permission.
  Future<bool> sendMessage(String vkToken, String userId, String message) async {
    if (vkToken.isEmpty || userId.isEmpty || message.isEmpty) {
      print("Error: VK Token, User ID, or Message is missing for sendMessage.");
      return false;
    }
    try {
      final response = await _dio.post( // Use POST for sending messages
        'messages.send',
        queryParameters: {
          'user_id': userId,
          'message': message,
          'access_token': vkToken,
          'random_id': Random().nextInt(2147483647), // Required parameter
        },
      );

      final responseData = _handleResponse(response);
      // VK API returns the message ID on success
      return responseData != null && responseData is int;

    } on DioException catch (e) {
      print("DioError sending message: ${e.message}");
      print("Response Data: ${e.response?.data}");
      // Handle specific errors like permission denied (error_code 901, 902 might relate to privacy), etc.
      return false; // Indicate failure
    } catch (e) {
      print("Error sending message: $e");
      return false; // Indicate failure
    }
  }
}

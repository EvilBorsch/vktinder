import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:vktinder/data/models/vk_group_user.dart';

class VkApiProvider extends GetxService {
  final Dio _dio = Dio();

  // Simulating API call to VK
  Future<List<VKGroupUser>> getGroupUsers(String vkToken) async {
    // In a real app, this would be an actual API call
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    final List<VKGroupUser> results = [];

    // Generate mock data
    for (int i = 0; i < 5; i++) {
      final randomWord = 'User $i';
      results.add(
        VKGroupUser(
          name: randomWord,
          surname: "ID: ${vkToken.length + i}",
          userID: "123",
          avatar: "http://10.0.2.2:8000/assets/ava.jpeg",
        ),
      );
    }

    return results;
  }

  Future<VKGroupUser> getFullProfile(String vkToken, String userID) async {
    // VK API endpoint example:
    // final response = await _dio.get(
    //   'https://api.vk.com/method/users.get',
    //   queryParameters: {
    //     'user_ids': userID,
    //     'fields': 'photo_max_orig,groups,interests',
    //     'access_token': vkToken,
    //     'v': '5.131',
    //   },
    // );
    // final userData = response.data['response'][0];
    var userData = {
      'response': [
        {
          'first_name': 'John',
          'last_name': 'Doe',
          'id': '123456789',
          'photo_max_orig': 'http://10.0.2.2:8000/assets/ava.jpeg',
          'groups': [ {'name': 'Photography'}, {'name': 'Music'},],
          'interests': ['Reading', 'Traveling'],
        },
      ],
    };
    return VKGroupUser.fromJson(userData['response']![0]);
  }

  Future<List<String>> getUserPhotos(String vkToken, String userID) async {
    // final response = await _dio.get(
    //   'https://api.vk.com/method/photos.get',
    //   queryParameters: {
    //     'owner_id': userID,
    //     'album_id': 'profile',
    //     'access_token': vkToken,
    //     'v': '5.131',
    //   },
    // );
    return ["http://10.0.2.2:8000/assets/ava.jpeg", "http://10.0.2.2:8000/assets/ava.jpeg", "http://10.0.2.2:8000/assets/ava.jpeg", "http://10.0.2.2:8000/assets/ava.jpeg", "http://10.0.2.2:8000/assets/ava.jpeg", "http://10.0.2.2:8000/assets/ava.jpeg", "http://10.0.2.2:8000/assets/ava.jpeg", "http://10.0.2.2:8000/assets/ava.jpeg", "http://10.0.2.2:8000/assets/ava.jpeg", "http://10.0.2.2:8000/assets/ava.jpeg"];
    // return response.data['response']['items']
    //     .map((photo) => photo['url'])
    //     .toList();
  }

  // Simulate sending a message to VK
  Future<bool> sendMessage(String vkToken, String userId,
      String message) async {
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 300));

    // Always return success in this mock implementation
    return true;
  }
}

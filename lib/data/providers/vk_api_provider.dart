import 'package:get/get.dart';
import 'package:vktinder/data/models/vk_group_user.dart';

class VkApiProvider extends GetxService {
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
          name: '$randomWord',
          surname: "ID: ${vkToken.length + i}",
        ),
      );
    }
    
    return results;
  }
  
  // Simulate sending a message to VK
  Future<bool> sendMessage(String vkToken, String userId, String message) async {
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Always return success in this mock implementation
    return true;
  }
}
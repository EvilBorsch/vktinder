import 'package:get/get.dart';
import 'package:vktinder/data/models/vk_group_user.dart';
import 'package:vktinder/data/repositories/statistics_repository.dart';


class StatisticsController extends GetxController {
  final StatisticsRepository _statisticsRepository =
      Get.find<StatisticsRepository>();

  final RxMap<String, RxList<VKGroupUser>> likedUsers =
      <String, RxList<VKGroupUser>>{}.obs;
  final RxList<String> skippedUserIDs = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    getSkippedIDs();
  }

  @override
  void onClose() {
    // Dispose text controllers
    super.onClose();
  }

  Future<void> addStatForLikedUser(String groupID, VKGroupUser user) async {
    await _statisticsRepository.saveLikedUser(groupID, user);
    if (!likedUsers.containsKey(groupID)) {
      likedUsers[groupID] = <VKGroupUser>[].obs;
    }
    likedUsers[groupID]!.add(user);
    await _statisticsRepository.saveSkippedUser(user.userID);
    skippedUserIDs.add(user.userID);
  }

  Future<void> getLikedUsers() async {
    var dbLikedUsers = await _statisticsRepository.getLikedUsers();
    Map<String, RxList<VKGroupUser>> observableDbUsers = {};
    dbLikedUsers.forEach((k, v){
      observableDbUsers[k] = v.obs;
    });
    likedUsers.value = observableDbUsers;
  }

  Future<void> getSkippedIDs() async {
    skippedUserIDs.value = await _statisticsRepository.getSkippedUsers();
  }
}

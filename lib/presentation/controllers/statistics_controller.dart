import 'package:get/get.dart';
import 'package:vktinder/data/models/statistics.dart';
import 'package:vktinder/data/repositories/statistics_repository.dart';


class StatisticsController extends GetxController {
  final StatisticsRepository _statisticsRepository =
      Get.find<StatisticsRepository>();

  final RxMap<String, RxList<StatisticsUserAction>> userActions =
      <String, RxList<StatisticsUserAction>>{}.obs;
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

  Future<void> addUserAction(String groupID, StatisticsUserAction action) async {
    await _statisticsRepository.saveUserAction(groupID, action);
    if (!userActions.containsKey(groupID)) {
      userActions[groupID] = <StatisticsUserAction>[].obs;
    }
    userActions[groupID]!.add(action);
    await _statisticsRepository.saveSkippedUser(action.user.userID);
    skippedUserIDs.add(action.user.userID);
  }

  Future<void> getUserActions() async {
    var dbActions = await _statisticsRepository.getUserActions();
    Map<String, RxList<StatisticsUserAction>> observableDbUsers = {};
    dbActions.forEach((k, v){
      observableDbUsers[k] = v.obs;
    });
    userActions.value = observableDbUsers;
  }

  Future<void> getSkippedIDs() async {
    skippedUserIDs.value = await _statisticsRepository.getSkippedUsers();
  }
}

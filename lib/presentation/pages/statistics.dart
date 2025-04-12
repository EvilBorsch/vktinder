import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vktinder/data/models/vk_group_user.dart';
import 'package:vktinder/presentation/controllers/statistics_controller.dart';

class StatisticsPage extends GetView<StatisticsController> {
  const StatisticsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    controller.getLikedUsers();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Статистика'),
        elevation: 1, // Subtle shadow
      ),
      body: Column(
        children: [
          Text("Я страничка\n"),
          Obx(() {
            var text = "";
            var currentUsers = controller.likedUsers;
            currentUsers.forEach((String groupID, List<VKGroupUser> groupUsers){
              text+="Группа: " + groupID;
              for (var user in groupUsers) {
                text += user.toString() + " ";
              }
            });
            return Text("Юзеры: " + text);
          })
        ],
      ),
    );
  }
}

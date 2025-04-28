import 'package:hive/hive.dart';

part 'statistics_user_action.g.dart';

@HiveType(typeId: 1)
class HiveStatisticsUserAction extends HiveObject {
  @HiveField(0)
  final String userId;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String surname;

  @HiveField(3)
  final String? avatar;

  @HiveField(4)
  final String? groupURL;

  @HiveField(5)
  final String? cityName;

  @HiveField(6)
  final String action;

  @HiveField(7)
  final DateTime actionDate;

  HiveStatisticsUserAction({
    required this.userId,
    required this.name,
    required this.surname,
    this.avatar,
    this.groupURL,
    this.cityName,
    required this.action,
    required this.actionDate,
  });

  // Convert from regular StatisticsUserAction
  factory HiveStatisticsUserAction.fromStatisticsUserAction(dynamic action) {
    return HiveStatisticsUserAction(
      userId: action.userId,
      name: action.name,
      surname: action.surname,
      avatar: action.avatar,
      groupURL: action.groupURL,
      cityName: action.cityName,
      action: action.action,
      actionDate: action.actionDate,
    );
  }

  // Convert to regular StatisticsUserAction
  dynamic toStatisticsUserAction() {
    // This will be implemented after we create a converter utility
    return {
      'userId': userId,
      'name': name,
      'surname': surname,
      'avatar': avatar,
      'groupURL': groupURL,
      'cityName': cityName,
      'action': action,
      'actionDate': actionDate.millisecondsSinceEpoch,
    };
  }
}
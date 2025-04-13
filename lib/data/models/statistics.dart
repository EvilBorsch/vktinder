// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:vktinder/data/models/vk_group_user.dart';

const ActionLike = "like";
const ActionDislike = "dislike";

class StatisticsUserAction {
  final VKGroupUser user;
  final String action;
  final DateTime actionDate;

  StatisticsUserAction(
    this.user,
    this.action,
    this.actionDate,
  );

  StatisticsUserAction copyWith({
    VKGroupUser? user,
    String? action,
    DateTime? actionDate,
  }) {
    return StatisticsUserAction(
      user ?? this.user,
      action ?? this.action,
      actionDate ?? this.actionDate,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'user': user.toJson(),
      'action': action,
      'actionDate': actionDate.millisecondsSinceEpoch,
    };
  }

  factory StatisticsUserAction.fromMap(Map<String, dynamic> map) {
    return StatisticsUserAction(
      VKGroupUser.fromJson(map['user'] as Map<String, dynamic>),
      map['action'] as String,
      DateTime.fromMillisecondsSinceEpoch(map['actionDate'] as int),
    );
  }

  String toJson() => json.encode(toMap());

  factory StatisticsUserAction.fromJson(String source) =>
      StatisticsUserAction.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'UserAction(user: $user, action: $action, actionDate: $actionDate)';

  @override
  bool operator ==(covariant StatisticsUserAction other) {
    if (identical(this, other)) return true;

    return other.user == user &&
        other.action == action &&
        other.actionDate == actionDate;
  }

  @override
  int get hashCode => user.hashCode ^ action.hashCode ^ actionDate.hashCode;
}

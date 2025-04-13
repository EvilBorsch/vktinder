// lib/data/models/statistics.dart
// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

// Keep VKGroupUser import for potential future use or reference, but don't store the full object
// import 'package:vktinder/data/models/vk_group_user.dart';

const ActionLike = "like";
const ActionDislike = "dislike";

class StatisticsUserAction {
  // Store only essential identifier and display data
  final String userId;
  final String name;
  final String surname;
  final String? avatar;
  final String? groupURL; // Keep group URL for grouping stats
  final String action; // 'like' or 'dislike'
  final DateTime actionDate;

  StatisticsUserAction({
    required this.userId,
    required this.name,
    required this.surname,
    this.avatar,
    this.groupURL,
    required this.action,
    required this.actionDate,
  });

  // --- Keep copyWith for potential internal use ---
  StatisticsUserAction copyWith({
    String? userId,
    String? name,
    String? surname,
    String? avatar,
    String? groupURL,
    String? action,
    DateTime? actionDate,
  }) {
    return StatisticsUserAction(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      surname: surname ?? this.surname,
      avatar: avatar ?? this.avatar,
      groupURL: groupURL ?? this.groupURL,
      action: action ?? this.action,
      actionDate: actionDate ?? this.actionDate,
    );
  }

  // --- Simplified Map Conversion ---
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'userId': userId, // Store only ID
      'name': name,
      'surname': surname,
      'avatar': avatar,
      'groupURL': groupURL,
      'action': action,
      'actionDate': actionDate.millisecondsSinceEpoch,
    };
  }

  factory StatisticsUserAction.fromMap(Map<String, dynamic> map) {
    // Handle potential legacy format where 'user' object was stored
    if (map.containsKey('user') && map['user'] is Map) {
      final userMap = map['user'] as Map<String, dynamic>;
      return StatisticsUserAction(
        // Extract necessary fields from the old 'user' map
        userId: (userMap['id'] ?? userMap['userID'] ?? '0').toString(), // Handle both 'id' and 'userID'
        name: userMap['first_name'] as String? ?? 'Имя',
        surname: userMap['last_name'] as String? ?? 'Фамилия',
        avatar: userMap['photo_max_orig'] as String? ?? // Use existing avatar logic
            userMap['photo_max'] as String? ??
            userMap['photo_200'] as String? ??
            userMap['photo_100'] as String? ??
            userMap['photo_50'] as String?, // Add fallback
        groupURL: userMap['groupURL'] as String?,
        action: map['action'] as String,
        actionDate: DateTime.fromMillisecondsSinceEpoch(map['actionDate'] as int),
      );
    } else {
      // Handle the new, flat format
      return StatisticsUserAction(
        userId: (map['userId'] ?? '0').toString(),
        name: map['name'] as String? ?? 'Имя',
        surname: map['surname'] as String? ?? 'Фамилия',
        avatar: map['avatar'] as String?,
        groupURL: map['groupURL'] as String?,
        action: map['action'] as String,
        actionDate: DateTime.fromMillisecondsSinceEpoch(map['actionDate'] as int),
      );
    }
  }

  String toJson() => json.encode(toMap());

  factory StatisticsUserAction.fromJson(String source) =>
      StatisticsUserAction.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'UserAction(userId: $userId, name: $name $surname, action: $action, date: $actionDate)';

  @override
  bool operator ==(covariant StatisticsUserAction other) {
    if (identical(this, other)) return true;

    // Compare relevant fields only
    return other.userId == userId &&
        other.action == action &&
        other.actionDate == actionDate &&
        other.groupURL == groupURL;
  }

  @override
  int get hashCode =>
      userId.hashCode ^ action.hashCode ^ actionDate.hashCode ^ groupURL.hashCode;
}

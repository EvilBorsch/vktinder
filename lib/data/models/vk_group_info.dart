// lib/data/models/vk_group_info.dart
class VKGroupInfo {
  final int id;
  final String name;
  final String screenName;
  final String? photo50; // Smallest photo typically available
  final String? photo100;
  final String? photo200;
  final int? membersCount;
  final String type; // e.g., 'group', 'page', 'event'

  VKGroupInfo({
    required this.id,
    required this.name,
    required this.screenName,
    this.photo50,
    this.photo100,
    this.photo200,
    this.membersCount,
    required this.type,
  });

  // Helper getter for the best available avatar
  String get avatarUrl =>
      photo200 ?? photo100 ?? photo50 ?? 'https://vk.com/images/community_100.png';

  factory VKGroupInfo.fromJson(Map<String, dynamic> json) {
    return VKGroupInfo(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Unknown Group',
      screenName: json['screen_name'] as String? ?? '',
      photo50: json['photo_50'] as String?,
      photo100: json['photo_100'] as String?,
      photo200: json['photo_200'] as String?,
      membersCount: json['members_count'] as int?,
      type: json['type'] as String? ?? 'group',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'screen_name': screenName,
    'photo_50': photo50,
    'photo_100': photo100,
    'photo_200': photo200,
    'members_count': membersCount,
    'type': type,
  };
}

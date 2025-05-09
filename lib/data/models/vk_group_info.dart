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
  final String? sourceUrl; // Optional: Store the original URL/screen_name used

  VKGroupInfo({
    required this.id,
    required this.name,
    required this.screenName,
    this.photo50,
    this.photo100,
    this.photo200,
    this.membersCount,
    required this.type,
    this.sourceUrl, // Add to constructor
  });

  // Helper getter for the best available avatar
  String get avatarUrl =>
      photo200 ?? photo100 ?? photo50 ?? 'https://vk.com/images/community_100.png';

  factory VKGroupInfo.fromJson(Map<dynamic, dynamic> json, {String? sourceUrl}) { // Add optional sourceUrl parameter
    return VKGroupInfo(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Unknown Group',
      screenName: json['screen_name'] as String? ?? '',
      photo50: json['photo_50'] as String?,
      photo100: json['photo_100'] as String?,
      photo200: json['photo_200'] as String?,
      membersCount: json['members_count'] as int?,
      type: json['type'] as String? ?? 'group',
      sourceUrl: json['sourceUrl'] as String? ?? sourceUrl, // First try to get from JSON, then use parameter
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
    'sourceUrl': sourceUrl, // Add to serialization if needed for storage
  };

  // Add copyWith for easily updating sourceUrl later if needed
  VKGroupInfo copyWith({
    int? id,
    String? name,
    String? screenName,
    String? photo50,
    String? photo100,
    String? photo200,
    int? membersCount,
    String? type,
    String? sourceUrl,
  }) {
    return VKGroupInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      screenName: screenName ?? this.screenName,
      photo50: photo50 ?? this.photo50,
      photo100: photo100 ?? this.photo100,
      photo200: photo200 ?? this.photo200,
      membersCount: membersCount ?? this.membersCount,
      type: type ?? this.type,
      sourceUrl: sourceUrl ?? this.sourceUrl,
    );
  }

  @override
  String toString() {
    return 'VKGroupInfo{id: $id, name: $name, screenName: $screenName, sourceUrl: $sourceUrl}';
  }

  // Consider overriding == and hashCode if using Sets or comparing
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is VKGroupInfo && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

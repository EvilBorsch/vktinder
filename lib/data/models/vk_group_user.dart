// --- File: lib/data/models/vk_group_user.dart ---
// lib/data/models/vk_group_user.dart
import 'vk_group_info.dart'; // Import the new model

class VKGroupUser {
  final String name;
  final String surname;
  final String userID;
  final String? avatar;
  final List<VKGroupInfo> groups; // Change to use VKGroupInfo
  List<String> photos;
  final List<String> interests;
  final String? about;
  final String? status;
  final String? bdate;
  final String? city;
  final String? country;
  final int? sex;
  final int? relation; // 0-not set, 1-single.. 6-in active search..
  final String? screenName;
  final bool? online;
  final Map<String, dynamic>? lastSeen;
  final bool? canWritePrivateMessage; // Keep for reference, might be useful
  final bool? canSeeAllPosts;         // New field to check profile access
  final String? groupURL;

  VKGroupUser({
    required this.name,
    required this.surname,
    required this.userID,
    this.avatar,
    this.groups = const [], // Initialize with an empty list of VKGroupInfo
    this.photos = const [],
    this.interests = const [],
    this.about,
    this.status,
    this.bdate,
    this.city,
    this.country,
    this.sex,
    this.relation,
    this.screenName,
    this.online,
    this.lastSeen,
    this.canWritePrivateMessage,
    this.canSeeAllPosts, // Add to constructor
    this.groupURL,
  });

  Map<String, dynamic> toJson() => {
    'id': int.tryParse(userID) ?? userID,
    'first_name': name,
    'last_name': surname,
    'photo_max_orig': avatar,
    'interests': interests.join(', '),
    'about': about,
    'status': status,
    'bdate': bdate,
    'city': city != null ? {'title': city} : null,
    'country': country != null ? {'title': country} : null,
    'sex': sex,
    'relation': relation,
    'screen_name': screenName,
    'online': online,
    'last_seen': lastSeen,
    'can_write_private_message': canWritePrivateMessage,
    'can_see_all_posts': canSeeAllPosts, // Add to JSON
    // Serialize groups correctly
    'groups': groups.map((g) => g.toJson()).toList(),
    'photos': photos,
    'groupURL': groupURL,
  };

  factory VKGroupUser.fromJson(Map<String, dynamic> json) {
    // Helper to safely parse comma-separated strings
    List<String> parseCommaSeparatedString(String? input) {
      if (input == null || input.trim().isEmpty) {
        return [];
      }
      return input
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    // Safely parse groups (if they somehow exist in the JSON during loading)
    List<VKGroupInfo> parsedGroups = [];
    if (json['groups'] != null && json['groups'] is List) {
      try {
        parsedGroups = (json['groups'] as List)
            .map((g) => VKGroupInfo.fromJson(g as Map<String, dynamic>))
            .toList();
      } catch (e) {
        print("Error parsing groups from JSON: $e");
        // Keep parsedGroups empty if parsing fails
      }
    }

    // Helper to parse boolean fields safely (handles int 0/1 or bool)
    bool? parseBool(dynamic value) {
      if (value == null) return null;
      if (value is bool) return value;
      if (value is int) return value == 1;
      if (value is String) {
        if (value.toLowerCase() == 'true') return true;
        if (value.toLowerCase() == 'false') return false;
        final intValue = int.tryParse(value);
        if (intValue != null) return intValue == 1;
      }
      return null; // Cannot determine boolean value
    }


    return VKGroupUser(
      // Handle possible ID formats (int from API, string from storage)
      userID: json['id'] is int
          ? (json['id'] as int).toString()
          : json['id']?.toString() ?? '0',

      name: json['first_name'] as String? ?? 'Имя',
      surname: json['last_name'] as String? ?? 'Фамилия',

      // Handle all possible photo fields with priority
      avatar: json['photo_max_orig'] as String? ??
          json['photo_max'] as String? ??
          json['photo_400_orig'] as String? ??
          json['photo_200_orig'] as String? ??
          json['photo_200'] as String? ??
          json['photo_100'] as String? ??
          json['photo_50'] as String? ??
          'https://vk.com/images/camera_200.png',

      // Parse interests safely
      interests: json['interests'] != null
          ? parseCommaSeparatedString(json['interests'] as String?)
          : const [],

      // Initialize other fields
      groups: parsedGroups, // Use the parsed groups or default empty list

      // Parse simple string fields
      about: json['about'] as String?,
      status: json['status'] as String?,
      bdate: json['bdate'] as String?,
      screenName: json['screen_name'] as String?,

      // Parse nested objects
      city: (json['city'] as Map<String, dynamic>?)?['title'] as String?,
      country: (json['country'] as Map<String, dynamic>?)?['title'] as String?,

      // Parse numeric fields
      sex: json['sex'] as int?,
      relation: json['relation'] as int?, // Parse relation

      // Parse boolean fields using helper
      online: parseBool(json['online']),
      canWritePrivateMessage: parseBool(json['can_write_private_message']),
      canSeeAllPosts: parseBool(json['can_see_all_posts']), // Parse new field

      // Parse complex/nested fields
      lastSeen: json['last_seen'] as Map<String, dynamic>?,

      // We expect photos to be populated separately later
      photos: (json['photos'] as List<dynamic>?)?.map((p) => p.toString()).toList() ?? const [],
      groupURL: json['groupURL'] as String?,
    );
  }

  // Make groups mutable if needed in the repository
  // Remove 'final' if you need to assign it later
  // List<VKGroupInfo> groups;

  @override
  String toString() => '{userID: $userID, name: $name, surname: $surname, relation: $relation, canSeeAllPosts: $canSeeAllPosts}, groupURL: $groupURL';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is VKGroupUser &&
              runtimeType == other.runtimeType &&
              userID == other.userID;

  @override
  int get hashCode => userID.hashCode;
}
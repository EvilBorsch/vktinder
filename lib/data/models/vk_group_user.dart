// --- File: lib/data/models/vk_group_user.dart ---
// lib/data/models/vk_group_user.dart
import 'vk_group_info.dart'; // Import the new model

class VKGroupUser {
  final String name;
  final String surname;
  final String userID;
  final String? avatar;
  final List<VKGroupInfo> groups; // Populated in detail view
  List<String> photos; // Populated in detail view
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
  final bool? canWritePrivateMessage;
  final bool? isClosed;
  final String? groupURL; // *** Make sure this exists ***

  VKGroupUser({
    required this.name,
    required this.surname,
    required this.userID,
    this.avatar,
    this.groups = const [],
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
    this.isClosed,
    this.groupURL, // *** Add to constructor ***
  });

  Map<String, dynamic> toJson() => {
    // Use string keys consistently for JSON
    'id': userID, // Save as string to avoid type issues on load
    'first_name': name,
    'last_name': surname,
    'photo_max_orig': avatar, // Include best avatar for potential re-use
    'interests': interests, // Save as list
    'about': about,
    'status': status,
    'bdate': bdate,
    'city': city, // Store simple string if already processed
    'country': country, // Store simple string if already processed
    'sex': sex,
    'relation': relation,
    'screen_name': screenName,
    'online': online,
    'last_seen': lastSeen, // VK format is fine here
    'can_write_private_message': canWritePrivateMessage,
    'is_closed': isClosed,
    'groupURL': groupURL, // *** Serialize groupURL ***
    // We generally DON'T save full photos/groups list in the persisted card stack
    // to keep it smaller. They are fetched on demand in the detail view.
    // 'photos': photos,
    // 'groups': groups.map((g) => g.toJson()).toList(),
    "photo_100": avatar, // Add basic avatar for card view consistency on load if needed
    "photo_200": avatar, // Add basic avatar for card view consistency on load if needed
  };

  factory VKGroupUser.fromJson(Map<String, dynamic> json) {
    // Helper to safely parse comma-separated strings (if needed from old API format)
    List<String> parseCommaSeparatedString(dynamic input) {
      if (input == null) return [];
      if (input is List) return List<String>.from(input); // Already a list (e.g., from our toJson)
      if (input is String && input.trim().isNotEmpty) {
        return input.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }
      return [];
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
      // Handle 'id' being int (from API) or String (from our JSON)
      userID: json['id']?.toString() ?? '0',

      name: json['first_name'] as String? ?? '?',
      surname: json['last_name'] as String? ?? '?',

      // Prioritize best photo available in the JSON
      avatar: json['photo_max_orig'] as String? ??
          json['photo_max'] as String? ??
          json['photo_400_orig'] as String? ??
          json['photo_200_orig'] as String? ??
          json['photo_200'] as String? ??
          json['photo_100'] as String? ??
          json['photo_50'] as String? ??
          'https://vk.com/images/camera_200.png', // Default placeholder

      // Interests might be stored as List<String> or comma-separated string
      interests: parseCommaSeparatedString(json['interests']),

      // Profile details
      about: json['about'] as String?,
      status: json['status'] as String?,
      bdate: json['bdate'] as String?,
      screenName: json['screen_name'] as String?,

      // Location: Handle both nested (API) and flat (our JSON) formats
      city: (json['city'] is Map<String, dynamic> ? json['city']['title'] : json['city']) as String?,
      country: (json['country'] is Map<String, dynamic> ? json['country']['title'] : json['country']) as String?,

      // Numeric/Bool fields
      sex: json['sex'] as int?,
      relation: json['relation'] as int?,
      online: parseBool(json['online']),
      canWritePrivateMessage: parseBool(json['can_write_private_message']),
      isClosed: parseBool(json['is_closed']),

      lastSeen: json['last_seen'] as Map<String, dynamic>?,

      // *** Deserialize groupURL ***
      groupURL: json['groupURL'] as String?,

      // Photos and Groups are usually NOT loaded from this initial JSON
      // They are fetched separately when viewing the full profile.
      // Initialize as empty lists.
      photos: (json['photos'] as List<dynamic>?)?.map((p) => p.toString()).toList() ?? const [], // Handle potential persistence
      groups: (json['groups'] as List<dynamic>?)?.map((g) => VKGroupInfo.fromJson(g as Map<String,dynamic>)).toList() ?? const [], // Handle potential persistence
    );
  }


  @override
  String toString() => '{userID: $userID, name: $name $surname, groupURL: $groupURL}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is VKGroupUser &&
              runtimeType == other.runtimeType &&
              userID == other.userID;

  @override
  int get hashCode => userID.hashCode;
}


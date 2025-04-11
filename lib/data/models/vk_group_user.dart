class VKGroupUser {
  final String name;
  final String surname;
  final String userID;
  final String? avatar;
  final List<String> groups;
  List<String> photos;
  final List<String> interests;
  final String? about;
  final String? status;
  final String? bdate;
  final String? city;
  final String? country;
  final int? sex;
  final int? relation;
  final String? screenName;
  final bool? online;
  final Map<String, dynamic>? lastSeen;

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
  });

  Map<String, dynamic> toJson() => {
    'id': int.tryParse(userID) ?? userID, // Convert back to int if possible
    'first_name': name,
    'last_name': surname,
    'photo_max_orig': avatar,
    'interests': interests.join(', '),
    'about': about,
    'status': status,
    'bdate': bdate,
    'city': city != null ? {'title': city} : null,
    'country': country != null ? {'title': country}: null,
    'sex': sex,
    'relation': relation,
    'screen_name': screenName,
    'online': online,
    'last_seen': lastSeen,
    'groups': groups,
    'photos': photos,
  };

  factory VKGroupUser.fromJson(Map<String, dynamic> json) {
    // Helper to safely parse comma-separated strings
    List<String> parseCommaSeparatedString(String? input) {
      if (input == null || input.trim().isEmpty) {
        return [];
      }
      return input.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
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
      groups: const [],  // Populated separately
      photos: const [],  // Populated separately

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
      relation: json['relation'] as int?,

      // Parse boolean fields
      online: json['online'] != null
          ? (json['online'] is bool
          ? json['online'] as bool
          : (json['online'] as int) == 1)
          : null,

      // Parse complex/nested fields
      lastSeen: json['last_seen'] as Map<String, dynamic>?,
    );
  }

  @override
  String toString() => '{userID: $userID, name: $name, surname: $surname}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is VKGroupUser &&
              runtimeType == other.runtimeType &&
              userID == other.userID;

  @override
  int get hashCode => userID.hashCode;
}

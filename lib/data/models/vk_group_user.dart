class VKGroupUser {
  final String name;
  final String surname;
  final String userID; // Add VK user ID for API calls
  final String? avatar;
  final List<String>? groups;
  List<String>? photos;
  final List<String>? interests;

  VKGroupUser({
    required this.name,
    required this.surname,
    required this.userID,
    this.avatar,
    this.groups,
    this.photos,
    this.interests,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'surname': surname,
    'user_id': userID,
    'avatar': avatar,
    'groups': groups,
    'photos': photos,
    'interests': interests,
  };

  factory VKGroupUser.fromJson(Map<String, dynamic> json) => VKGroupUser(
    name: json['first_name'] as String,
    surname: json['last_name'] as String,
    userID: json['id'] as String,
    avatar: json['photo_max_orig'] as String?,
    groups: (json['groups'] as List?)?.map((e) => e['name'] as String).toList(),
    photos: (json['photos'] as List?)?.map((e) => e as String).toList(),
    interests: json['interests'] as List<String>?,
  );

  @override
  String toString() => '{name: $name, surname: $surname}';
}

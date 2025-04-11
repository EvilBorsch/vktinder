class VKGroupUser {
  final String name;
  final String surname;
  final String userID; // VK User ID is integer, but API often accepts string. Keep String for flexibility.
  final String? avatar; // URL
  final List<String> groups; // Names of groups (populated in full profile)
  List<String> photos; // URLs (populated separately)
  final List<String> interests; // Parsed from comma-separated string
  // Add other fields you fetch in getFullProfile (e.g., bdate, city, about)
  final String? about;
  final String? status;
  final String? bdate;
  final String? city;
  final String? country;
  // ... add more fields as needed

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
  });

  // Note: toJson might not be needed unless you're saving the full fetched profile locally.
  // The current local storage saves the list fetched from getGroupUsers initially.
  Map<String, dynamic> toJson() => {
    'id': userID, // Use 'id' to match VK field name if saving
    'first_name': name,
    'last_name': surname,
    'photo_100': avatar, // Match the field requested in getGroupUsers if saving that list
    // For full profile save:
    'photo_max_orig': avatar,
    'interests': interests.join(', '), // Save back as string if needed
    'about': about,
    'status': status,
    'bdate': bdate,
    'city': city != null ? {'title': city} : null, // Reconstruct structure if needed
    'country': country != null ? {'title': country}: null, // Reconstruct structure if needed
    // Groups are more complex, might be list of objects or IDs
    'groups': groups, // This might need adjustment based on how you store/use it
    'photos': photos, // Usually not saved directly in user JSON
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
      // VK User ID is an integer, convert to String for consistency in the model
      userID: (json['id'] as int).toString(),
      name: json['first_name'] as String? ?? 'Имя',
      surname: json['last_name'] as String? ?? 'Фамилия',
      // Choose the appropriate photo field based on what you requested
      avatar: json['photo_max_orig'] as String? // For full profile
          ?? json['photo_100'] as String? // For group list
          ?? 'https://vk.com/images/camera_200.png', // Placeholder
      // Parse interests string only if available (from users.get)
      interests: parseCommaSeparatedString(json['interests'] as String?),
      // Groups might be complex. users.get might not return group names directly
      // You might need a separate call or handle IDs if 'groups' field is requested.
      // For simplicity here, assume it's not directly parsed or comes from another source later.
      groups: const [], // Placeholder, populate later if needed
      photos: const [], // Photos are fetched separately
      about: json['about'] as String?,
      status: json['status'] as String?,
      bdate: json['bdate'] as String?,
      city: (json['city'] as Map<String, dynamic>?)?['title'] as String?,
      country: (json['country'] as Map<String, dynamic>?)?['title'] as String?,
      // Add parsing for other fields...
    );
  }

  @override
  String toString() => '{userID: $userID, name: $name, surname: $surname}';

  // Override equality operator and hashCode if using these objects in Sets or as Map keys
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is VKGroupUser &&
              runtimeType == other.runtimeType &&
              userID == other.userID;

  @override
  int get hashCode => userID.hashCode;
}

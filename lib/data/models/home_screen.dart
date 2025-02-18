// Simple model for a "VKGroupUser"
class VKGroupUser {
  final String name;
  final String surname;

  const VKGroupUser({required this.name, required this.surname});

  Map<String, dynamic> toJson() => {'name': name, 'surname': surname};

  factory VKGroupUser.fromJson(Map<String, dynamic> json) => VKGroupUser(
    name: json['name'] as String,
    surname: json['surname'] as String,
  );

  @override
  String toString() => '{name: $name, surname: $surname}';
}

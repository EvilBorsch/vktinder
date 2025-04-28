// lib/data/models/vk_city_info.dart
import 'dart:convert';

class VKCityInfo {
  final int id;
  final String name;

  VKCityInfo({
    required this.id,
    required this.name,
  });

  factory VKCityInfo.fromJson(Map<String, dynamic> json) {
    return VKCityInfo(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Unknown City',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
  };

  String toJsonString() => json.encode(toJson());

  factory VKCityInfo.fromJsonString(String source) =>
      VKCityInfo.fromJson(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'VKCityInfo(id: $id, name: $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VKCityInfo && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

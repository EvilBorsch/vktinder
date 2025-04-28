import 'package:hive/hive.dart';

part 'vk_group_user.g.dart';

@HiveType(typeId: 2)
class HiveVKGroupUser extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final String surname;

  @HiveField(2)
  final String userID;

  @HiveField(3)
  final String? avatar;

  @HiveField(4)
  final List<String> interests;

  @HiveField(5)
  final String? about;

  @HiveField(6)
  final String? status;

  @HiveField(7)
  final String? bdate;

  @HiveField(8)
  final String? city;

  @HiveField(9)
  final String? country;

  @HiveField(10)
  final int? sex;

  @HiveField(11)
  final int? relation;

  @HiveField(12)
  final String? screenName;

  @HiveField(13)
  final bool? online;

  @HiveField(14)
  final Map<dynamic, dynamic>? lastSeen;

  @HiveField(15)
  final bool? canWritePrivateMessage;

  @HiveField(16)
  final bool? isClosed;

  @HiveField(17)
  final String? groupURL;

  @HiveField(18)
  final List<String> photos;

  HiveVKGroupUser({
    required this.name,
    required this.surname,
    required this.userID,
    this.avatar,
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
    this.groupURL,
    this.photos = const [],
  });

  // Convert from regular VKGroupUser
  factory HiveVKGroupUser.fromVKGroupUser(dynamic user) {
    return HiveVKGroupUser(
      name: user.name,
      surname: user.surname,
      userID: user.userID,
      avatar: user.avatar,
      interests: user.interests,
      about: user.about,
      status: user.status,
      bdate: user.bdate,
      city: user.city,
      country: user.country,
      sex: user.sex,
      relation: user.relation,
      screenName: user.screenName,
      online: user.online,
      lastSeen: user.lastSeen,
      canWritePrivateMessage: user.canWritePrivateMessage,
      isClosed: user.isClosed,
      groupURL: user.groupURL,
      photos: user.photos,
    );
  }

  // Convert to Map for creating regular VKGroupUser
  Map<String, dynamic> toVKGroupUserMap() {
    return {
      'id': userID,
      'first_name': name,
      'last_name': surname,
      'photo_max_orig': avatar,
      'interests': interests,
      'about': about,
      'status': status,
      'bdate': bdate,
      'city': city,
      'country': country,
      'sex': sex,
      'relation': relation,
      'screen_name': screenName,
      'online': online,
      'last_seen': lastSeen,
      'can_write_private_message': canWritePrivateMessage,
      'is_closed': isClosed,
      'groupURL': groupURL,
      'photos': photos,
    };
  }
}
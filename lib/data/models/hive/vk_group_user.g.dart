// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vk_group_user.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveVKGroupUserAdapter extends TypeAdapter<HiveVKGroupUser> {
  @override
  final int typeId = 2;

  @override
  HiveVKGroupUser read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveVKGroupUser(
      name: fields[0] as String,
      surname: fields[1] as String,
      userID: fields[2] as String,
      avatar: fields[3] as String?,
      interests: (fields[4] as List).cast<String>(),
      about: fields[5] as String?,
      status: fields[6] as String?,
      bdate: fields[7] as String?,
      city: fields[8] as String?,
      country: fields[9] as String?,
      sex: fields[10] as int?,
      relation: fields[11] as int?,
      screenName: fields[12] as String?,
      online: fields[13] as bool?,
      lastSeen: (fields[14] as Map?)?.cast<dynamic, dynamic>(),
      canWritePrivateMessage: fields[15] as bool?,
      isClosed: fields[16] as bool?,
      groupURL: fields[17] as String?,
      photos: (fields[18] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, HiveVKGroupUser obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.surname)
      ..writeByte(2)
      ..write(obj.userID)
      ..writeByte(3)
      ..write(obj.avatar)
      ..writeByte(4)
      ..write(obj.interests)
      ..writeByte(5)
      ..write(obj.about)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.bdate)
      ..writeByte(8)
      ..write(obj.city)
      ..writeByte(9)
      ..write(obj.country)
      ..writeByte(10)
      ..write(obj.sex)
      ..writeByte(11)
      ..write(obj.relation)
      ..writeByte(12)
      ..write(obj.screenName)
      ..writeByte(13)
      ..write(obj.online)
      ..writeByte(14)
      ..write(obj.lastSeen)
      ..writeByte(15)
      ..write(obj.canWritePrivateMessage)
      ..writeByte(16)
      ..write(obj.isClosed)
      ..writeByte(17)
      ..write(obj.groupURL)
      ..writeByte(18)
      ..write(obj.photos);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveVKGroupUserAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

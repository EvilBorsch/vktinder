// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'skipped_user_ids.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveSkippedUserIdsAdapter extends TypeAdapter<HiveSkippedUserIds> {
  @override
  final int typeId = 3;

  @override
  HiveSkippedUserIds read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveSkippedUserIds(
      userIds: (fields[0] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, HiveSkippedUserIds obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.userIds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveSkippedUserIdsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

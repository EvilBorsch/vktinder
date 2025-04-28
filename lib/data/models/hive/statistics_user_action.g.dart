// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'statistics_user_action.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveStatisticsUserActionAdapter
    extends TypeAdapter<HiveStatisticsUserAction> {
  @override
  final int typeId = 1;

  @override
  HiveStatisticsUserAction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveStatisticsUserAction(
      userId: fields[0] as String,
      name: fields[1] as String,
      surname: fields[2] as String,
      avatar: fields[3] as String?,
      groupURL: fields[4] as String?,
      cityName: fields[5] as String?,
      action: fields[6] as String,
      actionDate: fields[7] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, HiveStatisticsUserAction obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.surname)
      ..writeByte(3)
      ..write(obj.avatar)
      ..writeByte(4)
      ..write(obj.groupURL)
      ..writeByte(5)
      ..write(obj.cityName)
      ..writeByte(6)
      ..write(obj.action)
      ..writeByte(7)
      ..write(obj.actionDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveStatisticsUserActionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

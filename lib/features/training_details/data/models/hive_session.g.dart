// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_session.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveSessionAdapter extends TypeAdapter<HiveSession> {
  @override
  final int typeId = 0;

  @override
  HiveSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveSession()
      ..sessionId = fields[0] as String
      ..gymId = fields[1] as String
      ..userId = fields[2] as String
      ..deviceId = fields[3] as String
      ..deviceName = fields[4] as String
      ..deviceDescription = fields[5] as String?
      ..isMulti = fields[6] as bool
      ..exerciseId = fields[7] as String?
      ..exerciseName = fields[8] as String?
      ..timestamp = fields[9] as DateTime
      ..note = fields[10] as String?
      ..sets = (fields[11] as List).cast<HiveSessionSet>()
      ..startTime = fields[12] as DateTime?
      ..endTime = fields[13] as DateTime?
      ..durationMs = fields[14] as int?
      ..updatedAt = fields[15] as DateTime;
  }

  @override
  void write(BinaryWriter writer, HiveSession obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.sessionId)
      ..writeByte(1)
      ..write(obj.gymId)
      ..writeByte(2)
      ..write(obj.userId)
      ..writeByte(3)
      ..write(obj.deviceId)
      ..writeByte(4)
      ..write(obj.deviceName)
      ..writeByte(5)
      ..write(obj.deviceDescription)
      ..writeByte(6)
      ..write(obj.isMulti)
      ..writeByte(7)
      ..write(obj.exerciseId)
      ..writeByte(8)
      ..write(obj.exerciseName)
      ..writeByte(9)
      ..write(obj.timestamp)
      ..writeByte(10)
      ..write(obj.note)
      ..writeByte(11)
      ..write(obj.sets)
      ..writeByte(12)
      ..write(obj.startTime)
      ..writeByte(13)
      ..write(obj.endTime)
      ..writeByte(14)
      ..write(obj.durationMs)
      ..writeByte(15)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HiveSessionSetAdapter extends TypeAdapter<HiveSessionSet> {
  @override
  final int typeId = 1;

  @override
  HiveSessionSet read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveSessionSet()
      ..weight = fields[0] as double
      ..reps = fields[1] as int
      ..setNumber = fields[2] as int
      ..dropWeightKg = fields[3] as double
      ..dropReps = fields[4] as int
      ..isBodyweight = fields[5] as bool;
  }

  @override
  void write(BinaryWriter writer, HiveSessionSet obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.weight)
      ..writeByte(1)
      ..write(obj.reps)
      ..writeByte(2)
      ..write(obj.setNumber)
      ..writeByte(3)
      ..write(obj.dropWeightKg)
      ..writeByte(4)
      ..write(obj.dropReps)
      ..writeByte(5)
      ..write(obj.isBodyweight);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveSessionSetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

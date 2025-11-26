// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_sync_job.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveSyncJobAdapter extends TypeAdapter<HiveSyncJob> {
  @override
  final int typeId = 2;

  @override
  HiveSyncJob read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveSyncJob()
      ..id = fields[0] as String
      ..collection = fields[1] as String
      ..docId = fields[2] as String
      ..action = fields[3] as String
      ..payload = fields[4] as String
      ..createdAt = fields[5] as DateTime
      ..retryCount = fields[6] as int
      ..lastAttempt = fields[7] as DateTime?;
  }

  @override
  void write(BinaryWriter writer, HiveSyncJob obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.collection)
      ..writeByte(2)
      ..write(obj.docId)
      ..writeByte(3)
      ..write(obj.action)
      ..writeByte(4)
      ..write(obj.payload)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.retryCount)
      ..writeByte(7)
      ..write(obj.lastAttempt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveSyncJobAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

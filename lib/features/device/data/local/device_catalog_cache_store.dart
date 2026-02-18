import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../dtos/device_dto.dart';
import '../../domain/models/exercise.dart';

class DeviceCatalogCacheStore {
  const DeviceCatalogCacheStore();

  static String _devicesKey(String gymId) => 'deviceCatalog/devices/$gymId';

  static String _exercisesKey(String gymId, String deviceId, String userId) =>
      'deviceCatalog/exercises/$gymId/$deviceId/$userId';

  Future<List<DeviceDto>> readDevices(String gymId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_devicesKey(gymId));
    if (raw == null || raw.isEmpty) return const <DeviceDto>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <DeviceDto>[];
      final devices = <DeviceDto>[];
      for (final row in decoded) {
        if (row is! Map) continue;
        final map = row.map((key, value) => MapEntry('$key', value));
        final uid = (map['uid'] as String?)?.trim();
        if (uid == null || uid.isEmpty) continue;
        devices.add(
          DeviceDto(
            uid: uid,
            id: (map['id'] as num?)?.toInt() ?? 0,
            name: (map['name'] as String?) ?? '',
            description: (map['description'] as String?) ?? '',
            nfcCode: map['nfcCode'] as String?,
            isMulti: map['isMulti'] == true,
            muscleGroupIds: _toStringList(map['muscleGroupIds']),
            muscleGroups: _toStringList(map['muscleGroups']),
            primaryMuscleGroups: _toStringList(map['primaryMuscleGroups']),
            secondaryMuscleGroups: _toStringList(map['secondaryMuscleGroups']),
            manufacturerId: map['manufacturerId'] as String?,
            manufacturerName: map['manufacturerName'] as String?,
          ),
        );
      }
      return devices;
    } catch (_) {
      await prefs.remove(_devicesKey(gymId));
      return const <DeviceDto>[];
    }
  }

  Future<void> writeDevices(String gymId, List<DeviceDto> devices) async {
    final prefs = await SharedPreferences.getInstance();
    final serialized = <Map<String, dynamic>>[
      for (final device in devices)
        <String, dynamic>{
          'uid': device.uid,
          'id': device.id,
          'name': device.name,
          'description': device.description,
          'nfcCode': device.nfcCode,
          'isMulti': device.isMulti,
          'muscleGroupIds': device.muscleGroupIds,
          'muscleGroups': device.muscleGroups,
          'primaryMuscleGroups': device.primaryMuscleGroups,
          'secondaryMuscleGroups': device.secondaryMuscleGroups,
          'manufacturerId': device.manufacturerId,
          'manufacturerName': device.manufacturerName,
        },
    ];
    await prefs.setString(_devicesKey(gymId), jsonEncode(serialized));
  }

  Future<List<Exercise>> readExercises({
    required String gymId,
    required String deviceId,
    required String userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_exercisesKey(gymId, deviceId, userId));
    if (raw == null || raw.isEmpty) return const <Exercise>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <Exercise>[];
      final exercises = <Exercise>[];
      for (final row in decoded) {
        if (row is! Map) continue;
        final map = row.map((key, value) => MapEntry('$key', value));
        final id = (map['id'] as String?)?.trim();
        if (id == null || id.isEmpty) continue;
        exercises.add(Exercise.fromJson(map));
      }
      return exercises;
    } catch (_) {
      await prefs.remove(_exercisesKey(gymId, deviceId, userId));
      return const <Exercise>[];
    }
  }

  Future<void> writeExercises({
    required String gymId,
    required String deviceId,
    required String userId,
    required List<Exercise> exercises,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final serialized = <Map<String, dynamic>>[
      for (final exercise in exercises)
        <String, dynamic>{'id': exercise.id, ...exercise.toJson()},
    ];
    await prefs.setString(
      _exercisesKey(gymId, deviceId, userId),
      jsonEncode(serialized),
    );
  }

  List<String> _toStringList(dynamic value) {
    if (value is! List) return const <String>[];
    return value.map((entry) => '$entry').toList();
  }
}


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show immutable;

/// Immutable snapshot of a device session.
@immutable
class DeviceSessionSnapshot {
  final String sessionId;
  final String deviceId;
  final String? exerciseId;
  final DateTime createdAt;
  final String? note;
  final List<SetEntry> sets;
  final int renderVersion;
  final Map<String, dynamic>? uiHints;

  const DeviceSessionSnapshot({
    required this.sessionId,
    required this.deviceId,
    this.exerciseId,
    required this.createdAt,
    this.note,
    required this.sets,
    this.renderVersion = 1,
    this.uiHints,
  });

  factory DeviceSessionSnapshot.fromJson(Map<String, dynamic> j) {
    return DeviceSessionSnapshot(
      sessionId: j['sessionId'] as String,
      deviceId: j['deviceId'] as String,
      exerciseId: j['exerciseId'] as String?,
      createdAt: (j['createdAt'] as Timestamp).toDate(),
      note: j['note'] as String?,
      sets: (j['sets'] as List<dynamic>? ?? [])
          .map((e) => SetEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      renderVersion: j['renderVersion'] as int? ?? 1,
      uiHints: j['uiHints'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'deviceId': deviceId,
        'exerciseId': exerciseId,
        'createdAt': Timestamp.fromDate(createdAt),
        'note': note,
        'sets': sets.map((s) => s.toJson()).toList(),
        'renderVersion': renderVersion,
        'uiHints': uiHints,
      };
}

class SetEntry {
  final num kg;
  final int reps;
  final int? rir;
  final bool done;
  final String? note;
  final List<DropEntry> drops;

  const SetEntry({
    required this.kg,
    required this.reps,
    this.rir,
    this.done = false,
    this.note,
    this.drops = const [],
  });

  factory SetEntry.fromJson(Map<String, dynamic> j) => SetEntry(
        kg: j['kg'] as num,
        reps: j['reps'] as int,
        rir: j['rir'] as int?,
        done: j['done'] as bool? ?? false,
        note: j['note'] as String?,
        drops: (j['drops'] as List<dynamic>? ?? [])
            .map((e) => DropEntry.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'kg': kg,
        'reps': reps,
        'rir': rir,
        'done': done,
        'note': note,
        'drops': drops.map((d) => d.toJson()).toList(),
      };
}

class DropEntry {
  final num kg;
  final int reps;

  const DropEntry({
    required this.kg,
    required this.reps,
  });

  factory DropEntry.fromJson(Map<String, dynamic> j) => DropEntry(
        kg: j['kg'] as num,
        reps: j['reps'] as int,
      );

  Map<String, dynamic> toJson() => {
        'kg': kg,
        'reps': reps,
      };
}

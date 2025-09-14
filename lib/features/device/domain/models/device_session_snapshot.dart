import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show immutable;

/// Immutable snapshot of a device session.
@immutable
class DeviceSessionSnapshot {
  final String sessionId;
  final String deviceId;
  final String? exerciseId;
  final DateTime createdAt;
  final String userId;
  final String? note;
  final List<SetEntry> sets;
  final int renderVersion;
  final Map<String, dynamic>? uiHints;
  final bool isCardio;
  final String? mode;
  final int? durationSec;
  final double? speedKmH;

  const DeviceSessionSnapshot({
    required this.sessionId,
    required this.deviceId,
    this.exerciseId,
    required this.createdAt,
    required this.userId,
    this.note,
    required this.sets,
    this.renderVersion = 1,
    this.uiHints,
    this.isCardio = false,
    this.mode,
    this.durationSec,
    this.speedKmH,
  });

  factory DeviceSessionSnapshot.fromJson(Map<String, dynamic> j) {
    return DeviceSessionSnapshot(
      sessionId: j['sessionId'] as String,
      deviceId: j['deviceId'] as String,
      exerciseId: j['exerciseId'] as String?,
      createdAt: (j['createdAt'] as Timestamp).toDate(),
      userId: j['userId'] as String? ?? '',
      note: j['note'] as String?,
      sets: (j['sets'] as List<dynamic>? ?? [])
          .map((e) => SetEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      renderVersion: j['renderVersion'] as int? ?? 1,
      uiHints: j['uiHints'] as Map<String, dynamic>?,
      isCardio: j['isCardio'] as bool? ?? false,
      mode: j['mode'] as String?,
      durationSec: (j['durationSec'] as num?)?.toInt(),
      speedKmH: (j['speedKmH'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'deviceId': deviceId,
        'exerciseId': exerciseId,
        'createdAt': Timestamp.fromDate(createdAt),
        'userId': userId,
        'note': note,
        'sets': sets.map((s) => s.toJson()).toList(),
        'renderVersion': renderVersion,
        'uiHints': uiHints,
        'isCardio': isCardio,
        if (mode != null) 'mode': mode,
        if (durationSec != null) 'durationSec': durationSec,
        if (speedKmH != null) 'speedKmH': speedKmH,
      };
}

class SetEntry {
  final num? kg;
  final int? reps;
  final bool done;
  final List<DropEntry> drops;
  final bool isBodyweight;
  final num? speedKmH;
  final int? durationSec;

  const SetEntry({
    this.kg,
    this.reps,
    this.done = false,
    this.drops = const [],
    this.isBodyweight = false,
    this.speedKmH,
    this.durationSec,
  });

  factory SetEntry.fromJson(Map<String, dynamic> j) => SetEntry(
        kg: j['kg'] as num?,
        reps: j['reps'] as int?,
        done: j['done'] as bool? ?? false,
        drops: (j['drops'] as List<dynamic>? ?? [])
            .map((e) => DropEntry.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        isBodyweight: j['isBodyweight'] as bool? ?? false,
        speedKmH: j['speedKmH'] as num?,
        durationSec: j['durationSec'] as int?,
      );

  Map<String, dynamic> toJson() => {
        if (kg != null) 'kg': kg,
        if (reps != null) 'reps': reps,
        'done': done,
        'drops': drops.map((d) => d.toJson()).toList(),
        'isBodyweight': isBodyweight,
        if (speedKmH != null) 'speedKmH': speedKmH,
        if (durationSec != null) 'durationSec': durationSec,
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

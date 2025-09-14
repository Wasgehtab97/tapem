import 'dart:convert';

const int kDeviceDraftTtlMs = 60 * 60 * 1000; // 1 hour
const int kDeviceDraftDebounceMs = 350;

String buildDraftKey({
  required String gymId,
  required String userId,
  required String deviceId,
  String? exerciseId,
  required bool isMulti,
}) {
  final ex = isMulti ? (exerciseId ?? '') : '-';
  return '$gymId:$userId:$deviceId:$ex';
}

class SetDraft {
  final int index;
  final String weight;
  final String reps;
  final String speed;
  final String duration;
  final String? tempo;
  final String? dropWeight;
  final String? dropReps;
  final bool done;
  final bool isBodyweight;

  SetDraft({
    required this.index,
    this.weight = '',
    this.reps = '',
    this.speed = '',
    this.duration = '',
    this.tempo,
    this.dropWeight,
    this.dropReps,
    this.done = false,
    this.isBodyweight = false,
  });

  factory SetDraft.fromJson(Map<String, dynamic> json) => SetDraft(
        index: json['index'] as int,
        weight: json['weight'] as String? ?? '',
        reps: json['reps'] as String? ?? '',
        speed: json['speed'] as String? ?? '',
        duration: json['duration'] as String? ?? '',
        tempo: json['tempo'] as String?,
        dropWeight: json['dropWeight'] as String?,
        dropReps: json['dropReps'] as String?,
        done: json['done'] as bool? ?? false,
        isBodyweight: json['isBodyweight'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'index': index,
        'weight': weight,
        'reps': reps,
        'speed': speed,
        'duration': duration,
        if (tempo != null) 'tempo': tempo,
        if (dropWeight != null) 'dropWeight': dropWeight,
        if (dropReps != null) 'dropReps': dropReps,
        'done': done,
        if (isBodyweight) 'isBodyweight': true,
      };
}

class SessionDraft {
  final String deviceId;
  final String? exerciseId;
  final int createdAt;
  final int updatedAt;
  final int ttlMs;
  final String? units;
  final String note;
  final List<SetDraft> sets;
  final int? version;

  SessionDraft({
    required this.deviceId,
    this.exerciseId,
    required this.createdAt,
    required this.updatedAt,
    this.ttlMs = kDeviceDraftTtlMs,
    this.units,
    this.note = '',
    this.sets = const [],
    this.version,
  });

  factory SessionDraft.fromJson(Map<String, dynamic> json) => SessionDraft(
        deviceId: json['deviceId'] as String,
        exerciseId: json['exerciseId'] as String?,
        createdAt: json['createdAt'] as int,
        updatedAt: json['updatedAt'] as int,
        ttlMs: json['ttlMs'] as int? ?? kDeviceDraftTtlMs,
        units: json['units'] as String?,
        note: json['note'] as String? ?? '',
        sets: (json['sets'] as List<dynamic>? ?? [])
            .map((e) => SetDraft.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        version: json['version'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'deviceId': deviceId,
        if (exerciseId != null) 'exerciseId': exerciseId,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'ttlMs': ttlMs,
        if (units != null) 'units': units,
        'note': note,
        'sets': sets.map((e) => e.toJson()).toList(),
        if (version != null) 'version': version,
      };

  String encode() => jsonEncode(toJson());

  factory SessionDraft.decode(String source) =>
      SessionDraft.fromJson(jsonDecode(source) as Map<String, dynamic>);
}


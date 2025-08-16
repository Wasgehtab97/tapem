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

class DropSetDraft {
  final String weight;
  final String reps;

  DropSetDraft({this.weight = '', this.reps = ''});

  factory DropSetDraft.fromJson(Map<String, dynamic> json) => DropSetDraft(
        weight: json['weight'] as String? ?? '',
        reps: json['reps'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'weight': weight,
        'reps': reps,
      };
}

class SetDraft {
  final int index;
  final String weight;
  final String reps;
  final String? rir;
  final String? tempo;
  final String? note;
  final List<DropSetDraft> dropSets;
  final bool done;

  SetDraft({
    required this.index,
    this.weight = '',
    this.reps = '',
    this.rir,
    this.tempo,
    this.note,
    this.dropSets = const [],
    this.done = false,
  });

  factory SetDraft.fromJson(Map<String, dynamic> json) {
    final List<dynamic>? dropsRaw = json['dropSets'] as List<dynamic>?;
    List<DropSetDraft> drops =
        dropsRaw?.map((e) => DropSetDraft.fromJson(Map<String, dynamic>.from(e))).toList() ?? [];
    // backward compatibility: old single drop fields
    final dw = json['dropWeight'] as String?;
    final dr = json['dropReps'] as String?;
    if (drops.isEmpty && (dw != null || dr != null)) {
      drops = [DropSetDraft(weight: dw ?? '', reps: dr ?? '')];
    }
    return SetDraft(
      index: json['index'] as int,
      weight: json['weight'] as String? ?? '',
      reps: json['reps'] as String? ?? '',
      rir: json['rir'] as String?,
      tempo: json['tempo'] as String?,
      note: json['note'] as String?,
      dropSets: drops,
      done: json['done'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'index': index,
        'weight': weight,
        'reps': reps,
        if (rir != null) 'rir': rir,
        if (tempo != null) 'tempo': tempo,
        if (note != null) 'note': note,
        if (dropSets.isNotEmpty)
          'dropSets': dropSets.map((e) => e.toJson()).toList(),
        'done': done,
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


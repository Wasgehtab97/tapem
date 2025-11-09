import 'package:tapem/features/device/domain/models/device_session_snapshot.dart';

class SessionSetVM {
  final int ordinal; // 1,2,3… only for main sets
  final num kg;
  final int reps;
  final List<DropEntry> drops;
  final bool isBodyweight;
  const SessionSetVM({
    required this.ordinal,
    required this.kg,
    required this.reps,
    this.drops = const [],
    this.isBodyweight = false,
  });
}

List<SessionSetVM> mapSnapshotToVM(DeviceSessionSnapshot snap) {
  final vm = <SessionSetVM>[];
  var ordinal = 1;
  for (final s in snap.sets) {
    vm.add(SessionSetVM(
      ordinal: ordinal++,
      kg: s.kg,
      reps: s.reps,
      drops: s.drops,
      isBodyweight: s.isBodyweight,
    ));
  }
  return vm;
}

List<SessionSetVM> mapLegacySetsToVM(List<Map<String, dynamic>> sets) {
  final vm = <SessionSetVM>[];
  var ordinal = 1;

  String normalize(dynamic value) {
    final text = (value ?? '').toString().trim();
    if (text.toLowerCase() == 'null') return '';
    return text;
  }

  for (final s in sets) {
    final drops = <DropEntry>[];
    final rawDrops = s['drops'];
    if (rawDrops is List) {
      for (final drop in rawDrops) {
        if (drop is Map) {
          final map = Map<String, dynamic>.from(drop);
          final weightText = normalize(map['weight'] ?? map['kg']);
          final repsText = normalize(map['reps'] ?? map['wdh']);
          if (weightText.isEmpty || repsText.isEmpty) continue;
          final weight =
              num.tryParse(weightText.replaceAll(',', '.')) ?? 0;
          final reps =
              int.tryParse(repsText.replaceAll(',', '.')) ?? 0;
          drops.add(DropEntry(kg: weight, reps: reps));
        }
      }
    } else {
      final dropWeight = normalize(s['dropWeight']);
      final dropReps = normalize(s['dropReps']);
      if (dropWeight.isNotEmpty && dropReps.isNotEmpty) {
        drops.add(
          DropEntry(
            kg: num.tryParse(dropWeight.replaceAll(',', '.')) ?? 0,
            reps: int.tryParse(dropReps.replaceAll(',', '.')) ?? 0,
          ),
        );
      }
    }

    final weightText = normalize(s['weight'] ?? s['kg']);
    final kg = weightText.isEmpty
        ? null
        : num.tryParse(weightText.replaceAll(',', '.'));

    final repsText = normalize(s['reps'] ?? s['wdh']);
    final reps = repsText.isEmpty
        ? null
        : int.tryParse(repsText.replaceAll(',', '.'));

    final raw = s['isBodyweight'];
    final isBodyweight =
        raw is bool ? raw : raw?.toString().toLowerCase() == 'true';

    if (kg == null && reps == null && drops.isEmpty) {
      continue;
    }

    final shouldSkip = drops.isEmpty &&
        (kg ?? 0) <= 0 &&
        (reps ?? 0) <= 0 &&
        !(isBodyweight && (reps ?? 0) > 0);

    if (shouldSkip) {
      continue;
    }

    vm.add(SessionSetVM(
      ordinal: ordinal++,
      kg: kg ?? 0,
      reps: reps ?? 0,
      drops: drops,
      isBodyweight: isBodyweight,
    ));
  }
  return vm;
}

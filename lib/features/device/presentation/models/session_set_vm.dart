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
  for (final s in sets) {
    final drops = <DropEntry>[];
    final rawDrops = s['drops'];
    if (rawDrops is List) {
      for (final drop in rawDrops) {
        if (drop is Map) {
          final map = Map<String, dynamic>.from(drop);
          final weightText = (map['weight'] ?? map['kg'] ?? '').toString().trim();
          final repsText = (map['reps'] ?? map['wdh'] ?? '').toString().trim();
          if (weightText.isEmpty || repsText.isEmpty) continue;
          final weight =
              num.tryParse(weightText.replaceAll(',', '.')) ?? 0;
          final reps =
              int.tryParse(repsText.replaceAll(',', '.')) ?? 0;
          drops.add(DropEntry(kg: weight, reps: reps));
        }
      }
    } else {
      final dropWeight = (s['dropWeight'] ?? '').toString().trim();
      final dropReps = (s['dropReps'] ?? '').toString().trim();
      if (dropWeight.isNotEmpty && dropReps.isNotEmpty) {
        drops.add(
          DropEntry(
            kg: num.tryParse(dropWeight.replaceAll(',', '.')) ?? 0,
            reps: int.tryParse(dropReps.replaceAll(',', '.')) ?? 0,
          ),
        );
      }
    }
    final weightSource =
        (s['weight'] ?? s['kg'])?.toString() ?? '';
    final weightText = weightSource.trim();
    final kg = weightText.isEmpty
        ? null
        : num.tryParse(weightText.replaceAll(',', '.'));

    final repsSource =
        (s['reps'] ?? s['wdh'])?.toString() ?? '';
    final repsText = repsSource.trim();
    final reps = repsText.isEmpty
        ? null
        : int.tryParse(repsText.replaceAll(',', '.'));

    if (kg == null && reps == null && drops.isEmpty) {
      continue;
    }

    final raw = s['isBodyweight'];
    final isBodyweight =
        raw is bool ? raw : raw?.toString().toLowerCase() == 'true';
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

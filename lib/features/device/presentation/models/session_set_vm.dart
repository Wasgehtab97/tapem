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
    final List<DropEntry> drops =
        (s['dropWeight'] != null && s['dropWeight']!.isNotEmpty &&
                s['dropReps'] != null && s['dropReps']!.isNotEmpty)
            ? [
                DropEntry(
                  kg: num.tryParse(s['dropWeight']!) ?? 0,
                  reps: int.tryParse(s['dropReps']!) ?? 0,
                )
              ]
            : <DropEntry>[];
    vm.add(SessionSetVM(
      ordinal: ordinal++,
      kg: num.tryParse(s['weight']?.toString() ?? '0') ?? 0,
      reps: int.tryParse(s['reps']?.toString() ?? '0') ?? 0,
      drops: drops,
      isBodyweight: (s['isBodyweight'] ?? 'false') == 'true',
    ));
  }
  return vm;
}

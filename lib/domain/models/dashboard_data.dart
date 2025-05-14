import 'package:tapem/domain/models/device_info.dart';
import 'package:tapem/domain/models/exercise_entry.dart';

/// Zusammenfassung aller Dashboard-Daten.
class DashboardData {
  final DeviceInfo device;
  final List<ExerciseEntry> entries;

  DashboardData({
    required this.device,
    required this.entries,
  });
}

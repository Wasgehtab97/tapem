import 'package:collection/collection.dart';
import 'package:tapem/features/rank/domain/services/level_service.dart';

/// Helper to split XP per muscle group following the same weighting logic as
/// used during session XP creation.
class MuscleXpCalculator {
  static final _listEquality = const ListEquality<String>();

  /// Calculates the XP delta per muscle group for a single session.
  ///
  /// [primaryMuscleGroupIds] receive double weight compared to [secondaryMuscleGroupIds].
  /// Duplicate ids are ignored while maintaining insertion order.
  static Map<String, int> calculateDelta(
    List<String> primaryMuscleGroupIds,
    List<String> secondaryMuscleGroupIds,
  ) {
    final order = <String>[];
    final weights = <String, int>{};
    final seenPrimary = <String>{};
    final seenSecondary = <String>{};

    void push(String id, int weight, Set<String> seen) {
      if (id.isEmpty) return;
      if (seen.add(id)) {
        order.add(id);
      }
      weights[id] = (weights[id] ?? 0) + weight;
    }

    for (final id in primaryMuscleGroupIds) {
      push(id, 2, seenPrimary);
    }
    for (final id in secondaryMuscleGroupIds) {
      if (seenPrimary.contains(id)) {
        continue;
      }
      push(id, 1, seenSecondary);
    }

    final totalWeight = weights.values.fold<int>(0, (sum, w) => sum + w);
    if (totalWeight == 0) {
      return const {};
    }

    final baseXp = LevelService.xpPerSession;
    final xpPerWeight = baseXp ~/ totalWeight;
    var remainder = baseXp % totalWeight;
    final delta = <String, int>{};
    for (final id in order) {
      final weight = weights[id] ?? 0;
      if (weight == 0) continue;
      var value = weight * xpPerWeight;
      if (remainder > 0) {
        value += 1;
        remainder -= 1;
      }
      delta[id] = value;
    }
    return delta;
  }

  static bool listsEqual(List<String> a, List<String> b) =>
      _listEquality.equals(a, b);
}

/// Utilities for calculating estimated one-repetition maximum (e1RM).
///
/// Currently implements the Epley formula: `weightKg * (1 + reps / 30)`.
/// Returns `null` when the input values are not positive or missing.
double? calculateEpleyOneRepMax({
  required double? weightKg,
  required int? reps,
}) {
  if (weightKg == null || reps == null) {
    return null;
  }
  if (weightKg <= 0 || reps <= 0) {
    return null;
  }
  return weightKg * (1 + reps / 30);
}

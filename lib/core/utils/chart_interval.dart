import 'dart:math' as math;

/// Result of resolving a safe axis interval.
class AxisInterval {
  final double interval;
  final bool showTitles;
  const AxisInterval(this.interval, this.showTitles);
}

/// Computes a positive interval for chart axes.
///
/// Returns [AxisInterval] with [showTitles] set to false if the range
/// is invalid or zero. The [interval] will always be > 0 to satisfy
/// fl_chart's assertions. The number of labels is clamped by
/// [maxLabels] to avoid overcrowding.
AxisInterval resolveAxisInterval(double min, double max,
    {int targetLabels = 5, int maxLabels = 10, double fallback = 1}) {
  final range = max - min;
  if (!range.isFinite || range <= 0) {
    return AxisInterval(fallback, false);
  }
  double interval = range / math.max(1, targetLabels);
  if (!interval.isFinite || interval <= 0) {
    return AxisInterval(fallback, false);
  }
  final labelCount = (range / interval).ceil();
  if (labelCount > maxLabels) {
    interval = range / maxLabels;
  }
  if (interval <= 0 || !interval.isFinite) {
    interval = fallback;
  }
  return AxisInterval(interval, true);
}

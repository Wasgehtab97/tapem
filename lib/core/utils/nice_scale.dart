import 'dart:math' as math;

class NiceScale {
  final double min;
  final double max;
  final double tickSpacing;

  const NiceScale._(this.min, this.max, this.tickSpacing);

  factory NiceScale.fromValues(
    List<double> values, {
    int tickCount = 5,
    bool forceMinZero = false,
    bool clampMinZero = true,
  }) {
    if (values.isEmpty) {
      return const NiceScale._(0, 1, 1);
    }
    double minV = values.reduce(math.min);
    double maxV = values.reduce(math.max);

    if (minV == maxV) {
      double pad = math.max(minV.abs() * 0.05, 1);
      minV -= pad;
      maxV += pad;
    } else {
      final range = maxV - minV;
      final pad = range * 0.1;
      minV -= pad;
      maxV += pad;
    }

    if (forceMinZero) {
      minV = 0;
    } else if (clampMinZero && minV < 0) {
      minV = 0;
    }

    final range = maxV - minV;
    final rawStep = range / (tickCount - 1);
    final step = _niceNum(rawStep, round: true);
    final niceMin = (minV / step).floor() * step;
    final niceMax = (maxV / step).ceil() * step;
    return NiceScale._(niceMin, niceMax, step);
  }

  static double _niceNum(double value, {bool round = false}) {
    final exponent = (math.log(value) / math.ln10).floor();
    final fraction = value / math.pow(10, exponent);

    double niceFraction;
    if (round) {
      if (fraction < 1.5) {
        niceFraction = 1;
      } else if (fraction < 3) {
        niceFraction = 2;
      } else if (fraction < 7) {
        niceFraction = 5;
      } else {
        niceFraction = 10;
      }
    } else {
      if (fraction <= 1) {
        niceFraction = 1;
      } else if (fraction <= 2) {
        niceFraction = 2;
      } else if (fraction <= 5) {
        niceFraction = 5;
      } else {
        niceFraction = 10;
      }
    }
    return niceFraction * math.pow(10, exponent);
  }
}

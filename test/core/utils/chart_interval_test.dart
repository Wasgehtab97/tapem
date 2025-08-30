import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/core/utils/chart_interval.dart';

void main() {
  test('zero range disables titles and uses fallback interval', () {
    final res = resolveAxisInterval(0, 0);
    expect(res.showTitles, isFalse);
    expect(res.interval, greaterThan(0));
  });

  test('tiny range still yields positive interval', () {
    final res = resolveAxisInterval(0, 0.001);
    expect(res.showTitles, isTrue);
    expect(res.interval, greaterThan(0));
  });

  test('normal range computes expected interval', () {
    final res = resolveAxisInterval(0, 100, targetLabels: 5);
    expect(res.showTitles, isTrue);
    expect(res.interval, closeTo(20, 0.0001));
  });
}

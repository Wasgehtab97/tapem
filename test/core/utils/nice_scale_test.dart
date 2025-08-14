import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/core/utils/nice_scale.dart';

void main() {
  test('broad range produces nice bounds', () {
    final s = NiceScale.fromValues([2, 10, 12], tickCount: 5);
    expect(s.min, 0);
    expect(s.max >= 12, isTrue);
    expect(s.tickSpacing > 0, isTrue);
  });

  test('single value expands range', () {
    final s = NiceScale.fromValues([10], tickCount: 5);
    expect(s.max > s.min, isTrue);
    expect(s.min < 10 && s.max > 10, isTrue);
  });

  test('identical values expands range', () {
    final s = NiceScale.fromValues([5, 5, 5], tickCount: 5);
    expect(s.min < 5 && s.max > 5, isTrue);
  });

  test('forceMinZero clamps to zero', () {
    final s = NiceScale.fromValues([1, 2, 3], tickCount: 5, forceMinZero: true);
    expect(s.min, 0);
  });
}

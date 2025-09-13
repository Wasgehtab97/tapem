import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/features/xp/domain/apply_xp.dart';

void main() {
  test('950 +50 -> level up', () {
    final res = applyXp(xp: 950, level: 1, add: 50);
    expect(res.xp, 0);
    expect(res.level, 2);
    expect(res.leveledUp, true);
  });

  test('multiple overflow', () {
    final res = applyXp(xp: 1950, level: 1, add: 200);
    expect(res.xp, 150);
    expect(res.level, 3);
    expect(res.leveledUp, true);
  });

  test('at max level', () {
    final res = applyXp(xp: 900, level: 30, add: 200);
    expect(res.xp, 0);
    expect(res.level, 30);
    expect(res.leveledUp, false);
  });
}

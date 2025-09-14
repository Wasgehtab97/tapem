import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/core/util/interval_utils.dart';

void main() {
  test('intervals match total when sums are equal', () {
    expect(intervalsMatchTotal([10, 20, 30], 60), true);
  });

  test('intervals do not match total when sums differ', () {
    expect(intervalsMatchTotal([10, 20], 40), false);
  });
}

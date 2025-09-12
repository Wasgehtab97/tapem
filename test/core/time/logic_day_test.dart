import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/core/time/logic_day.dart';

void main() {
  test('returns YYYY-MM-DD for local date', () {
    final dt = DateTime.parse('2024-03-01T12:00:00+02:00');
    expect(logicDayKey(dt), '2024-03-01');
  });

  test('keeps start day across midnight', () {
    final start = DateTime(2024, 03, 01, 23, 30);
    expect(logicDayKey(start), '2024-03-01');
  });
}

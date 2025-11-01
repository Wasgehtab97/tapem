import 'package:flutter_test/flutter_test.dart';

import 'package:tapem/core/time/time_windows.dart';

void main() {
  group('TimeWindows', () {
    test('todayUtcRange returns expected UTC midnight bounds', () {
      final now = DateTime(2024, 11, 1, 15, 30);
      final window = todayUtcRange(now);
      expect(window.startUtc.isUtc, isTrue);
      expect(window.endUtc.isUtc, isTrue);
      expect(window.endUtc.difference(window.startUtc), const Duration(days: 1));
      expect(window.startUtc.hour, 0);
      expect(window.startUtc.minute, 0);
    });

    test('weekUtcRange anchors on Monday', () {
      final wednesday = DateTime(2024, 5, 15, 8);
      final window = weekUtcRange(wednesday);
      expect(window.startUtc.weekday, DateTime.monday);
      expect(window.endUtc.difference(window.startUtc), const Duration(days: 7));
    });

    test('todayUtcRange honours DST transitions with custom resolver', () {
      final offsets = <String, Duration>{
        '2024-03-31': const Duration(hours: 1),
        '2024-04-01': const Duration(hours: 2),
      };
      Duration resolver(DateTime date) {
        final key = '${date.year.toString().padLeft(4, '0')}-'
            '${date.month.toString().padLeft(2, '0')}-'
            '${date.day.toString().padLeft(2, '0')}';
        return offsets[key] ?? const Duration(hours: 1);
      }

      final dstDay = DateTime(2024, 3, 31, 10);
      final window = todayUtcRange(dstDay, offsetResolver: resolver);
      expect(window.startUtc, DateTime.utc(2024, 3, 30, 23));
      expect(window.endUtc, DateTime.utc(2024, 3, 31, 22));
    });
  });
}

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/core/utils/duration_format.dart';

void main() {
  test('formats hours correctly', () {
    final d = Duration(hours: 1, minutes: 30);
    expect(formatDuration(d, locale: const Locale('de')), '1 h 30 min');
    expect(formatDuration(d, locale: const Locale('en')), '1 h 30 min');
  });

  test('formats minutes correctly', () {
    final d = Duration(minutes: 5);
    expect(formatDuration(d, locale: const Locale('de')), '5 min');
  });

  test('formats seconds correctly', () {
    final d = Duration(seconds: 45);
    expect(formatDuration(d, locale: const Locale('en')), '45 s');
  });

  test('formats HH:mm correctly', () {
    final d1 = Duration(hours: 1, minutes: 5);
    expect(formatDurationHm(d1), '01:05');
    final d2 = Duration(minutes: 7);
    expect(formatDurationHm(d2), '00:07');
  });
}

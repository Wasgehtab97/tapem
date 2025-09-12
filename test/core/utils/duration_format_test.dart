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
}

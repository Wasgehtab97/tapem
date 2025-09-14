import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/core/util/number_utils.dart';
import 'package:tapem/core/config/remote_config.dart';

void main() {
  group('parseLenientDouble', () {
    test('accepts integers and decimals', () {
      expect(parseLenientDouble('5'), 5);
      expect(parseLenientDouble('10'), 10);
      expect(parseLenientDouble('10.5'), 10.5);
      expect(parseLenientDouble('10,5'), 10.5);
      expect(parseLenientDouble('005'), 5);
    });

    test('trims whitespace and separators', () {
      expect(parseLenientDouble(' 10 , 5 '), 10.5);
    });

    test('returns null on invalid input', () {
      expect(parseLenientDouble('abc'), isNull);
      expect(parseLenientDouble(''), isNull);
    });
  });

  group('isValidSpeed', () {
    final max = RC.cardioMaxSpeedFrom(40);
    test('invalid cases', () {
      expect(isValidSpeed('0', max), false);
      expect(isValidSpeed('-1', max), false);
      expect(isValidSpeed('41', max), false);
    });
  });

  test('remote config fallback', () {
    expect(RC.cardioMaxSpeedFrom(0), 40);
  });
}

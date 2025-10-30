import 'package:flutter_test/flutter_test.dart';

import 'package:tapem/features/onboarding_funnel/domain/utils/member_number_utils.dart';

void main() {
  group('normalizeMemberNumber', () {
    test('pads shorter values', () {
      expect(normalizeMemberNumber('7'), '0007');
      expect(normalizeMemberNumber('42'), '0042');
    });

    test('keeps four digit values unchanged', () {
      expect(normalizeMemberNumber('1234'), '1234');
    });

    test('returns last four digits when longer', () {
      expect(normalizeMemberNumber('123456'), '3456');
    });

    test('removes non digit characters', () {
      expect(normalizeMemberNumber('AB-12 3'), '0123');
    });

    test('returns null when there are no digits', () {
      expect(normalizeMemberNumber('abcd'), isNull);
    });
  });
}

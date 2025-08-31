import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/features/profile/presentation/widgets/change_username_sheet.dart';

void main() {
  group('username normalization and validation', () {
    test('collapses spaces and trims', () {
      expect(normalizeUsername('  foo  bar  '), 'foo bar');
    });

    test('allows spaces and enforces length', () {
      expect(isValidUsername('foo bar'), isTrue);
      expect(isValidUsername('fo'), isFalse);
      expect(isValidUsername('a' * 21), isFalse);
    });

    test('normalizes double spaces', () {
      expect(normalizeUsername('foo  bar'), 'foo bar');
    });
  });

  group('canSubmitUsername', () {
    const current = 'current';

    test('enables for non-taken states', () {
      for (final state in [
        UsernameAvailability.idle,
        UsernameAvailability.loading,
        UsernameAvailability.available,
        UsernameAvailability.error,
      ]) {
        expect(
          canSubmitUsername(
            input: 'new name',
            current: current,
            availability: state,
            submitting: false,
          ),
          isTrue,
          reason: 'state: $state',
        );
      }
    });

    test('disables when taken or same as current', () {
      expect(
        canSubmitUsername(
          input: 'new name',
          current: current,
          availability: UsernameAvailability.taken,
          submitting: false,
        ),
        isFalse,
      );
      expect(
        canSubmitUsername(
          input: 'Current',
          current: current,
          availability: UsernameAvailability.available,
          submitting: false,
        ),
        isFalse,
      );
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/core/providers/device_provider.dart';

void main() {
  group('DeviceProvider prefill helpers', () {
    test(
      'buildPrefilledSetFromPrevious fills empty set and marks prefilled',
      () {
        final current = <String, dynamic>{
          'number': '1',
          'weight': '',
          'reps': '',
          'dropWeight': '',
          'dropReps': '',
          'done': false,
          'isBodyweight': false,
          DeviceProvider.prefilledFromPreviousKey: false,
        };
        final previous = <String, dynamic>{
          'number': '1',
          'weight': '22',
          'reps': '3',
          'done': true,
          'isBodyweight': false,
        };

        final prefilled = DeviceProvider.buildPrefilledSetFromPrevious(
          currentSet: current,
          previousSet: previous,
        );

        expect(prefilled, isNotNull);
        expect(prefilled!['weight'], '22');
        expect(prefilled['reps'], '3');
        expect(prefilled['done'], false);
        expect(prefilled[DeviceProvider.prefilledFromPreviousKey], true);
      },
    );

    test(
      'buildPrefilledSetFromPrevious keeps weight empty for BW with 0kg',
      () {
        final current = <String, dynamic>{
          'number': '1',
          'weight': '',
          'reps': '',
          'dropWeight': '',
          'dropReps': '',
          'done': false,
          'isBodyweight': false,
        };
        final previous = <String, dynamic>{
          'number': '1',
          'weight': '0',
          'reps': '12',
          'done': true,
          'isBodyweight': true,
        };

        final prefilled = DeviceProvider.buildPrefilledSetFromPrevious(
          currentSet: current,
          previousSet: previous,
        );

        expect(prefilled, isNotNull);
        expect(prefilled!['isBodyweight'], true);
        expect(prefilled['weight'], '');
        expect(prefilled['reps'], '12');
      },
    );

    test(
      'buildPrefilledSetFromPrevious skips when current set already has data',
      () {
        final current = <String, dynamic>{
          'number': '1',
          'weight': '10',
          'reps': '',
          'done': false,
        };
        final previous = <String, dynamic>{
          'number': '1',
          'weight': '22',
          'reps': '3',
          'done': true,
          'isBodyweight': false,
        };

        final prefilled = DeviceProvider.buildPrefilledSetFromPrevious(
          currentSet: current,
          previousSet: previous,
        );

        expect(prefilled, isNull);
      },
    );

    test('shouldCountAsFilledNotDone ignores untouched prefilled sets', () {
      final untouchedPrefill = <String, dynamic>{
        'weight': '22',
        'reps': '3',
        'done': false,
        'isBodyweight': false,
        DeviceProvider.prefilledFromPreviousKey: true,
      };
      final userTouched = <String, dynamic>{
        'weight': '22',
        'reps': '3',
        'done': false,
        'isBodyweight': false,
        DeviceProvider.prefilledFromPreviousKey: false,
      };

      expect(
        DeviceProvider.shouldCountAsFilledNotDone(untouchedPrefill),
        isFalse,
      );
      expect(DeviceProvider.shouldCountAsFilledNotDone(userTouched), isTrue);
    });

    test('shouldCountAsFilledNotDone allows bodyweight reps-only sets', () {
      final bodyweightRepsOnly = <String, dynamic>{
        'weight': '',
        'reps': '15',
        'done': false,
        'isBodyweight': true,
        DeviceProvider.prefilledFromPreviousKey: false,
      };

      expect(
        DeviceProvider.shouldCountAsFilledNotDone(bodyweightRepsOnly),
        isTrue,
      );
    });

    test('shouldCountAsFilledNotDone rejects bodyweight sets without reps', () {
      final bodyweightNoReps = <String, dynamic>{
        'weight': '',
        'reps': '',
        'done': false,
        'isBodyweight': true,
        DeviceProvider.prefilledFromPreviousKey: false,
      };

      expect(
        DeviceProvider.shouldCountAsFilledNotDone(bodyweightNoReps),
        isFalse,
      );
    });
  });
}

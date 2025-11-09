import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/features/device/presentation/models/session_set_vm.dart';

void main() {
  group('mapLegacySetsToVM', () {
    test('treats boolean isBodyweight flag as true', () {
      final sets = [
        {
          'weight': '10',
          'reps': '5',
          'isBodyweight': true,
        }
      ];

      final vm = mapLegacySetsToVM(sets);

      expect(vm, hasLength(1));
      expect(vm.first.isBodyweight, isTrue);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tapem/features/gym/domain/services/gym_code_service.dart';
import 'package:tapem/features/gym/domain/usecases/validate_gym_code.dart';

class _MockGymCodeService extends Mock implements GymCodeService {}

void main() {
  group('ValidateGymCode', () {
    test('returns validation result from service', () async {
      final service = _MockGymCodeService();
      final result = GymCodeValidationResult(
        gymId: 'gym-1',
        gymName: 'Test Gym',
        code: 'ABCDEF',
        expiresAt: DateTime(2025, 1, 1),
      );

      when(() => service.validateCode('ABCDEF'))
          .thenAnswer((_) async => result);

      final usecase = ValidateGymCode(service);
      final resolved = await usecase.execute('ABCDEF');

      expect(resolved.gymId, result.gymId);
      expect(resolved.code, result.code);
      verify(() => service.validateCode('ABCDEF')).called(1);
    });

    test('bubbles up gym code exceptions', () async {
      final service = _MockGymCodeService();
      when(() => service.validateCode('ABCDEF'))
          .thenThrow(const GymCodeNotFoundException());

      final usecase = ValidateGymCode(service);

      await expectLater(
        usecase.execute('ABCDEF'),
        throwsA(isA<GymCodeNotFoundException>()),
      );
    });
  });
}

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tapem/features/nfc/data/nfc_service.dart';
import 'package:tapem/features/nfc/domain/usecases/read_nfc_code.dart';

class _MockNfcService extends Mock implements NfcService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReadNfcCode', () {
    late _MockNfcService service;
    late ReadNfcCode useCase;

    setUp(() {
      service = _MockNfcService();
      useCase = ReadNfcCode(service);
    });

    test('returns the raw stream from the service', () async {
      final controller = StreamController<String>();
      addTearDown(controller.close);
      when(() => service.readStream()).thenAnswer((_) => controller.stream);

      final result = useCase.execute();

      expect(result, same(controller.stream));
    });

    test('forwards every NFC code emitted by the service', () async {
      when(() => service.readStream())
          .thenAnswer((_) => Stream<String>.fromIterable(['a', 'b', 'c']));

      await expectLater(
        useCase.execute(),
        emitsInOrder(<Object?>['a', 'b', 'c', emitsDone]),
      );

      verify(() => service.readStream()).called(1);
    });
  });
}

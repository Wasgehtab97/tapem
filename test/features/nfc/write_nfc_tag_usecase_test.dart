import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ndef/ndef.dart' show TypeNameFormat;
import 'package:tapem/features/nfc/domain/usecases/write_nfc_tag.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('flutter_nfc_kit/method');
  final recordedCalls = <MethodCall>[];
  final availabilityQueue = <String>[];
  var throwOnWrite = false;

  setUp(() {
    recordedCalls.clear();
    availabilityQueue.clear();
    throwOnWrite = false;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      recordedCalls.add(call);
      switch (call.method) {
        case 'getNFCAvailability':
          return availabilityQueue.isNotEmpty
              ? availabilityQueue.removeAt(0)
              : 'available';
        case 'poll':
          return <String, dynamic>{
            'type': 'iso14443',
            'id': 'tag',
            'standard': 'iso14443',
            'historicalBytes': '',
            'protocolInfo': '',
            'applicationData': '',
            'atqa': '',
            'sak': '',
            'hiLayerResponse': '',
            'manufacturer': '',
            'systemCode': '',
            'identifier': '',
            'ndefAvailable': true,
            'ndefType': 'NDEF',
            'ndefCapacity': 1,
            'ndefWritable': true,
            'ndefCanMakeReadOnly': false,
            'additionalData': <String, dynamic>{},
          };
        case 'writeNDEFRawRecords':
          if (throwOnWrite) {
            throw PlatformException(code: 'write_failed', message: 'failed');
          }
          return null;
        case 'finish':
          return null;
        default:
          return null;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('WriteNfcTagUseCase', () {
    test('throws when NFC is not supported', () async {
      availabilityQueue.add('notSupported');
      final useCase = WriteNfcTagUseCase();

      expect(
        () => useCase.execute('abcd'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('NFC wird auf diesem Gerät nicht unterstützt.'),
        )),
      );

      expect(
        recordedCalls.map((call) => call.method),
        contains('getNFCAvailability'),
      );
    });

    test('polls, writes payload and finishes session on success', () async {
      availabilityQueue.add('available');
      final useCase = WriteNfcTagUseCase();

      await useCase.execute('hello');

      final methodNames = recordedCalls.map((call) => call.method).toList();
      expect(
        methodNames,
        containsAllInOrder([
          'getNFCAvailability',
          'poll',
          'writeNDEFRawRecords',
          'finish',
        ]),
      );

      final pollCall =
          recordedCalls.firstWhere((call) => call.method == 'poll');
      final pollArgs = pollCall.arguments as Map<dynamic, dynamic>;
      expect(pollArgs['iosAlertMessage'],
          'Bitte halte dein Gerät an den NFC-Tag');
      expect(pollArgs['iosMultipleTagMessage'],
          'Mehrere Tags erkannt – bitte nur ein Tag halten.');
      expect(pollArgs['timeout'], const Duration(seconds: 10).inMilliseconds);

      final writeCall =
          recordedCalls.firstWhere((call) => call.method == 'writeNDEFRawRecords');
      final records = writeCall.arguments as List<dynamic>;
      final record = records.first as Map<dynamic, dynamic>;
      expect(record['payload'], '02656e68656c6c6f');
      expect(record['type'], '54');
      expect(record['typeNameFormat'], TypeNameFormat.nfcWellKnown.index);

      final finishCall =
          recordedCalls.firstWhere((call) => call.method == 'finish');
      final finishArgs = finishCall.arguments as Map<dynamic, dynamic>;
      expect(finishArgs['iosAlertMessage'], 'Schreiben abgeschlossen');
    });

    test('always finishes session even when write fails', () async {
      availabilityQueue.add('available');
      throwOnWrite = true;
      final useCase = WriteNfcTagUseCase();

      try {
        await useCase.execute('deadbeef');
        fail('expected execute to throw');
      } catch (_) {
        // expected
      }

      final methodNames = recordedCalls.map((call) => call.method).toList();
      final writeIndex = methodNames.indexOf('writeNDEFRawRecords');
      final finishIndex = methodNames.indexOf('finish');
      expect(writeIndex, isNonNegative);
      expect(finishIndex, isNonNegative);
      expect(finishIndex, greaterThan(writeIndex));
    });
  });
}

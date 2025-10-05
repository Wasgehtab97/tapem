import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tapem/services/audio/timer_audio_service.dart';
import 'package:tapem/ui/timer/session_timer_service.dart';

class _MockTimerAudioService extends Mock implements TimerAudioService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  _MockTimerAudioService createAudioMock() {
    final audio = _MockTimerAudioService();
    when(audio.preload).thenAnswer((_) async {});
    when(audio.playPreAlert).thenAnswer((_) async {});
    when(audio.playEnd).thenAnswer((_) async {});
    when(audio.dispose).thenAnswer((_) async {});
    return audio;
  }

  testWidgets('fires pre-alert once per countdown and plays end sound', (tester) async {
    final audio = createAudioMock();
    final service = SessionTimerService(
      initialDuration: const Duration(seconds: 5),
      preAlertAt: const Duration(seconds: 3),
      audioService: audio,
    );

    service.startWith(const Duration(seconds: 5));

    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 1));

    verify(() => audio.preload()).called(1);
    verify(() => audio.playPreAlert()).called(1);
    verify(() => audio.playEnd()).called(1);

    service.dispose();
    await tester.pump();
    verify(() => audio.dispose()).called(1);
  });

  testWidgets('skips pre-alert when starting below threshold', (tester) async {
    final audio = createAudioMock();
    final service = SessionTimerService(
      initialDuration: const Duration(seconds: 2),
      preAlertAt: const Duration(seconds: 3),
      audioService: audio,
    );

    service.startWith(const Duration(seconds: 2));

    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    verifyNever(() => audio.playPreAlert());
    verify(() => audio.playEnd()).called(1);

    service.dispose();
    await tester.pump();
  });

  testWidgets('resets pre-alert after stop and restart', (tester) async {
    final audio = createAudioMock();
    final service = SessionTimerService(
      initialDuration: const Duration(seconds: 5),
      preAlertAt: const Duration(seconds: 3),
      audioService: audio,
    );

    service.startWith(const Duration(seconds: 5));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    service.stop();
    await tester.pump();

    verifyNever(() => audio.playPreAlert());

    service.startWith(const Duration(seconds: 5));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    verify(() => audio.playPreAlert()).called(1);

    service.dispose();
    await tester.pump();
  });
}

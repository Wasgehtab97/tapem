import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/ui/timer/session_timer_bar.dart';

void main() {
  testWidgets('SessionTimerBar ticks and completes respecting mute',
      (tester) async {
    final ticks = <Duration>[];
    bool done = false;
    int soundCalls = 0;
    int hapticCalls = 0;

    ServicesBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'SystemSound.play') soundCalls++;
      if (call.method == 'HapticFeedback.mediumImpact') hapticCalls++;
      return null;
    });
    addTearDown(() {
      ServicesBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    await tester.pumpWidget(MaterialApp(
      home: SessionTimerBar(
        total: const Duration(seconds: 2),
        initiallyRunning: true,
        onTick: ticks.add,
        onDone: () => done = true,
      ),
    ));

    expect(find.text('00:02'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('00:01'), findsOneWidget);
    expect(ticks.last, const Duration(seconds: 1));

    await tester.pump(const Duration(seconds: 1));
    expect(done, isTrue);
    expect(soundCalls, 1);
    expect(hapticCalls, 1);

    done = false;
    soundCalls = 0;
    hapticCalls = 0;

    await tester.pumpWidget(MaterialApp(
      home: SessionTimerBar(
        total: const Duration(seconds: 1),
        initiallyRunning: true,
        muted: true,
        onDone: () => done = true,
      ),
    ));

    await tester.pump(const Duration(seconds: 1));
    expect(done, isTrue);
    expect(soundCalls, 0);
    expect(hapticCalls, 1);
  });
}


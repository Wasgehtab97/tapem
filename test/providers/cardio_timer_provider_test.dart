import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/features/device/presentation/providers/cardio_timer_provider.dart';

void main() {
  test('state transitions idle -> running -> stopped', () async {
    final prov = CardioTimerProvider();
    expect(prov.state, CardioTimerState.idle);
    prov.start();
    expect(prov.state, CardioTimerState.running);
    await Future.delayed(const Duration(seconds: 1));
    prov.pause();
    expect(prov.state, CardioTimerState.stopped);
    expect(prov.elapsedSec > 0, true);
    prov.reset();
    expect(prov.state, CardioTimerState.idle);
    expect(prov.elapsedSec, 0);
  });
}

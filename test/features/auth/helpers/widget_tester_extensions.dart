import 'package:flutter_test/flutter_test.dart';

/// Extensions that provide deterministic alternatives to [WidgetTester]
/// helpers such as [WidgetTester.pumpAndSettle].
extension WidgetTesterAsyncExtensions on WidgetTester {
  /// Repeatedly pumps frames until [finder] matches at least one widget or the
  /// optional [timeout] is reached.
  Future<void> pumpUntilVisible(
    Finder finder, {
    Duration timeout = const Duration(seconds: 5),
    Duration step = const Duration(milliseconds: 16),
  }) async {
    if (finder.evaluate().isNotEmpty) {
      return;
    }
    final endTime = binding.clock.now().add(timeout);
    while (binding.clock.now().isBefore(endTime)) {
      await pump(step);
      if (finder.evaluate().isNotEmpty) {
        return;
      }
    }
    fail('pumpUntilVisible timed out waiting for $finder');
  }

  /// Repeatedly pumps frames until [finder] stops matching widgets or the
  /// optional [timeout] is reached.
  Future<void> pumpUntilAbsent(
    Finder finder, {
    Duration timeout = const Duration(seconds: 5),
    Duration step = const Duration(milliseconds: 16),
  }) async {
    if (finder.evaluate().isEmpty) {
      return;
    }
    final endTime = binding.clock.now().add(timeout);
    while (binding.clock.now().isBefore(endTime)) {
      await pump(step);
      if (finder.evaluate().isEmpty) {
        return;
      }
    }
    fail('pumpUntilAbsent timed out waiting for $finder to disappear');
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tapem/core/observability/offline_flow_observability_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late OfflineFlowObservabilityService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    service = OfflineFlowObservabilityService.instance;
    await service.resetForTests();
  });

  test('records offline starts and local save successes', () async {
    await service.recordOfflineStart();
    await service.recordOfflineStart();
    await service.recordLocalSessionSaveSuccess();

    final metrics = service.metrics;
    expect(metrics.offlineStarts, 2);
    expect(metrics.localSaveSuccesses, 1);
    expect(metrics.activeAlert, isNull);
  });

  test('records sync cycle metrics and triggers backlog alert', () async {
    await service.recordSyncCycle(
      pendingCount: 32,
      deadLetterCount: 1,
      processedJobs: 10,
      reconcileDuration: const Duration(milliseconds: 4200),
      averageQueueLatencyMs: 780,
    );

    final metrics = service.metrics;
    expect(metrics.pendingCount, 32);
    expect(metrics.deadLetterCount, 1);
    expect(metrics.lastReconcileDurationMs, 4200);
    expect(metrics.lastQueueLatencyMs, 780);
    expect(metrics.avgQueueLatencyMs, 780);
    expect(metrics.activeAlert?.kind, OfflineFlowAlertKind.syncBacklog);
  });

  test('triggers dead-letter spike alert and clears it again', () async {
    await service.recordQueueSnapshot(pendingCount: 8, deadLetterCount: 5);
    expect(
      service.metrics.activeAlert?.kind,
      OfflineFlowAlertKind.deadLetterSpike,
    );

    await service.recordQueueSnapshot(pendingCount: 0, deadLetterCount: 0);
    expect(service.metrics.activeAlert, isNull);
  });
}

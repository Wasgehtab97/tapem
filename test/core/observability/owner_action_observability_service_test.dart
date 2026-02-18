import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/core/observability/owner_action_observability_service.dart';

void main() {
  late OwnerActionObservabilityService service;

  setUp(() {
    service = OwnerActionObservabilityService.instance;
    service.resetForTests();
  });

  test('tracks successful command metrics', () async {
    final result = await service.trackAction<int>(
      action: 'owner.test.success',
      command: () async => 42,
    );

    expect(result, 42);
    final metric = service.metrics.metricFor('owner.test.success');
    expect(metric.attempts, 1);
    expect(metric.successes, 1);
    expect(metric.failures, 0);
    expect(metric.permissionDenied, 0);
    expect(metric.successRate, 1);
    expect(metric.failedCommandRate, 0);
    expect(metric.permissionDeniedRate, 0);
    expect(metric.updatedAt, isNotNull);

    expect(service.metrics.totalAttempts, 1);
    expect(service.metrics.totalSuccesses, 1);
    expect(service.metrics.totalFailures, 0);
    expect(service.metrics.totalPermissionDenied, 0);
  });

  test(
    'tracks permission denied as failed command and permission denial',
    () async {
      await expectLater(
        () => service.trackAction<void>(
          action: 'owner.test.permission_denied',
          command: () async {
            throw FirebaseException(
              plugin: 'cloud_firestore',
              code: 'permission-denied',
              message: 'Missing or insufficient permissions.',
            );
          },
        ),
        throwsA(isA<FirebaseException>()),
      );

      final metric = service.metrics.metricFor('owner.test.permission_denied');
      expect(metric.attempts, 1);
      expect(metric.successes, 0);
      expect(metric.failures, 1);
      expect(metric.permissionDenied, 1);
      expect(metric.lastErrorCode, 'permission-denied');
      expect(metric.successRate, 0);
      expect(metric.failedCommandRate, 1);
      expect(metric.permissionDeniedRate, 1);

      expect(service.metrics.totalAttempts, 1);
      expect(service.metrics.totalSuccesses, 0);
      expect(service.metrics.totalFailures, 1);
      expect(service.metrics.totalPermissionDenied, 1);
    },
  );

  test('tracks multiple outcomes and updates aggregate rates', () async {
    await service.trackAction<void>(
      action: 'owner.test.mixed',
      command: () async {},
    );
    await expectLater(
      () => service.trackAction<void>(
        action: 'owner.test.mixed',
        command: () async {
          throw StateError('boom');
        },
      ),
      throwsA(isA<StateError>()),
    );

    final metric = service.metrics.metricFor('owner.test.mixed');
    expect(metric.attempts, 2);
    expect(metric.successes, 1);
    expect(metric.failures, 1);
    expect(metric.permissionDenied, 0);
    expect(metric.successRate, 0.5);
    expect(metric.failedCommandRate, 0.5);
    expect(metric.permissionDeniedRate, 0);

    expect(service.metrics.successRate, 0.5);
    expect(service.metrics.failedCommandRate, 0.5);
    expect(service.metrics.permissionDeniedRate, 0);
  });
}

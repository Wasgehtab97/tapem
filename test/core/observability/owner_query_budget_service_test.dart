import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/core/observability/owner_query_budget_service.dart';

void main() {
  late OwnerQueryBudgetService service;

  setUp(() {
    service = OwnerQueryBudgetService();
    service.resetForTests();
  });

  test('tracks query and document metrics for a successful flow', () async {
    final result = await service.track<int>(
      flow: 'owner.report.usage_stats',
      budget: const OwnerQueryBudget(maxQueries: 5, maxDocsRead: 20),
      command: (counter) async {
        counter.recordQueryResult(docsRead: 3);
        counter.recordQueryResult(docsRead: 7);
        return 42;
      },
    );

    expect(result, 42);
    final metric = service.metrics.metricFor('owner.report.usage_stats');
    expect(metric.runs, 1);
    expect(metric.failures, 0);
    expect(metric.budgetBreaches, 0);
    expect(metric.lastQueries, 2);
    expect(metric.lastDocsRead, 10);
    expect(metric.lastBudgetExceeded, isFalse);
    expect(metric.updatedAt, isNotNull);
  });

  test('increments budget breaches when query budget is exceeded', () async {
    await service.track<void>(
      flow: 'owner.report.members_training_day_counts',
      budget: const OwnerQueryBudget(maxQueries: 2, maxDocsRead: 10),
      command: (counter) async {
        counter.recordQueryResult(docsRead: 4);
        counter.recordQueryResult(docsRead: 4);
        counter.recordQueryResult(docsRead: 4);
      },
    );

    final metric = service.metrics.metricFor(
      'owner.report.members_training_day_counts',
    );
    expect(metric.runs, 1);
    expect(metric.budgetBreaches, 1);
    expect(metric.lastBudgetExceeded, isTrue);
    expect(metric.lastQueries, 3);
    expect(metric.lastDocsRead, 12);
  });

  test('tracks failures and preserves measured counters', () async {
    await expectLater(
      () => service.track<void>(
        flow: 'owner.workspace.snapshot',
        budget: const OwnerQueryBudget(maxQueries: 5, maxDocsRead: 10),
        command: (counter) async {
          counter.recordQueryResult(docsRead: 2);
          throw StateError('boom');
        },
      ),
      throwsA(isA<StateError>()),
    );

    final metric = service.metrics.metricFor('owner.workspace.snapshot');
    expect(metric.runs, 1);
    expect(metric.failures, 1);
    expect(metric.lastQueries, 1);
    expect(metric.lastDocsRead, 2);
  });
}

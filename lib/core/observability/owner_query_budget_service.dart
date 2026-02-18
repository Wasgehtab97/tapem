import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

@immutable
class OwnerQueryBudget {
  const OwnerQueryBudget({required this.maxQueries, required this.maxDocsRead});

  final int maxQueries;
  final int maxDocsRead;
}

class OwnerQueryCounter {
  int _queries = 0;
  int _docsRead = 0;

  int get queries => _queries;
  int get docsRead => _docsRead;

  void recordQueryResult({required int docsRead}) {
    _queries += 1;
    _docsRead += docsRead < 0 ? 0 : docsRead;
  }
}

@immutable
class OwnerQueryMetric {
  const OwnerQueryMetric({
    required this.runs,
    required this.failures,
    required this.budgetBreaches,
    required this.avgQueries,
    required this.avgDocsRead,
    required this.avgLatencyMs,
    required this.lastQueries,
    required this.lastDocsRead,
    required this.lastBudgetExceeded,
    required this.updatedAt,
    this.lastErrorCode,
  });

  static const OwnerQueryMetric initial = OwnerQueryMetric(
    runs: 0,
    failures: 0,
    budgetBreaches: 0,
    avgQueries: 0,
    avgDocsRead: 0,
    avgLatencyMs: 0,
    lastQueries: 0,
    lastDocsRead: 0,
    lastBudgetExceeded: false,
    updatedAt: null,
  );

  final int runs;
  final int failures;
  final int budgetBreaches;
  final double avgQueries;
  final double avgDocsRead;
  final double avgLatencyMs;
  final int lastQueries;
  final int lastDocsRead;
  final bool lastBudgetExceeded;
  final DateTime? updatedAt;
  final String? lastErrorCode;

  OwnerQueryMetric copyWith({
    int? runs,
    int? failures,
    int? budgetBreaches,
    double? avgQueries,
    double? avgDocsRead,
    double? avgLatencyMs,
    int? lastQueries,
    int? lastDocsRead,
    bool? lastBudgetExceeded,
    DateTime? updatedAt,
    String? lastErrorCode,
    bool clearLastErrorCode = false,
  }) {
    return OwnerQueryMetric(
      runs: runs ?? this.runs,
      failures: failures ?? this.failures,
      budgetBreaches: budgetBreaches ?? this.budgetBreaches,
      avgQueries: avgQueries ?? this.avgQueries,
      avgDocsRead: avgDocsRead ?? this.avgDocsRead,
      avgLatencyMs: avgLatencyMs ?? this.avgLatencyMs,
      lastQueries: lastQueries ?? this.lastQueries,
      lastDocsRead: lastDocsRead ?? this.lastDocsRead,
      lastBudgetExceeded: lastBudgetExceeded ?? this.lastBudgetExceeded,
      updatedAt: updatedAt ?? this.updatedAt,
      lastErrorCode: clearLastErrorCode
          ? null
          : (lastErrorCode ?? this.lastErrorCode),
    );
  }
}

@immutable
class OwnerQueryBudgetSnapshot {
  const OwnerQueryBudgetSnapshot({required this.flows});

  static const OwnerQueryBudgetSnapshot initial = OwnerQueryBudgetSnapshot(
    flows: <String, OwnerQueryMetric>{},
  );

  final Map<String, OwnerQueryMetric> flows;

  OwnerQueryMetric metricFor(String flow) {
    return flows[flow] ?? OwnerQueryMetric.initial;
  }
}

class OwnerQueryBudgetService {
  OwnerQueryBudgetService();

  static final OwnerQueryBudgetService instance = OwnerQueryBudgetService();

  final ValueNotifier<OwnerQueryBudgetSnapshot> _metrics =
      ValueNotifier<OwnerQueryBudgetSnapshot>(OwnerQueryBudgetSnapshot.initial);

  ValueListenable<OwnerQueryBudgetSnapshot> get metricsListenable => _metrics;
  OwnerQueryBudgetSnapshot get metrics => _metrics.value;

  Future<T> track<T>({
    required String flow,
    required OwnerQueryBudget budget,
    required Future<T> Function(OwnerQueryCounter counter) command,
  }) async {
    final startedAt = DateTime.now();
    final counter = OwnerQueryCounter();
    try {
      final result = await command(counter);
      _record(
        flow: flow,
        budget: budget,
        counter: counter,
        startedAt: startedAt,
        succeeded: true,
      );
      return result;
    } catch (error, stackTrace) {
      _record(
        flow: flow,
        budget: budget,
        counter: counter,
        startedAt: startedAt,
        succeeded: false,
        errorCode: _extractErrorCode(error),
      );
      if (kDebugMode) {
        debugPrint('[OwnerQueryBudget] flow=$flow failed error=$error');
        debugPrint('$stackTrace');
      }
      rethrow;
    }
  }

  @visibleForTesting
  void resetForTests() {
    _metrics.value = OwnerQueryBudgetSnapshot.initial;
  }

  void _record({
    required String flow,
    required OwnerQueryBudget budget,
    required OwnerQueryCounter counter,
    required DateTime startedAt,
    required bool succeeded,
    String? errorCode,
  }) {
    final now = DateTime.now();
    final durationMs = now.difference(startedAt).inMilliseconds.toDouble();
    final exceedsBudget =
        counter.queries > budget.maxQueries ||
        counter.docsRead > budget.maxDocsRead;

    final current = _metrics.value;
    final previousMetric = current.flows[flow] ?? OwnerQueryMetric.initial;
    final runs = previousMetric.runs + 1;
    final avgQueries =
        ((previousMetric.avgQueries * previousMetric.runs) + counter.queries) /
        runs;
    final avgDocsRead =
        ((previousMetric.avgDocsRead * previousMetric.runs) +
            counter.docsRead) /
        runs;
    final avgLatencyMs =
        ((previousMetric.avgLatencyMs * previousMetric.runs) + durationMs) /
        runs;

    final nextMetric = previousMetric.copyWith(
      runs: runs,
      failures: previousMetric.failures + (succeeded ? 0 : 1),
      budgetBreaches: previousMetric.budgetBreaches + (exceedsBudget ? 1 : 0),
      avgQueries: avgQueries,
      avgDocsRead: avgDocsRead,
      avgLatencyMs: avgLatencyMs,
      lastQueries: counter.queries,
      lastDocsRead: counter.docsRead,
      lastBudgetExceeded: exceedsBudget,
      updatedAt: now,
      lastErrorCode: errorCode,
      clearLastErrorCode: succeeded,
    );

    final updatedFlows = <String, OwnerQueryMetric>{
      ...current.flows,
      flow: nextMetric,
    };
    _metrics.value = OwnerQueryBudgetSnapshot(flows: updatedFlows);

    if (kDebugMode && exceedsBudget) {
      debugPrint(
        '[OwnerQueryBudget] flow=$flow exceeded '
        '(queries=${counter.queries}/${budget.maxQueries}, '
        'docs=${counter.docsRead}/${budget.maxDocsRead})',
      );
    }
  }

  String? _extractErrorCode(Object error) {
    if (error is FirebaseException && error.code.isNotEmpty) {
      return error.code;
    }
    if (error is PlatformException && error.code.isNotEmpty) {
      return error.code;
    }
    return null;
  }
}

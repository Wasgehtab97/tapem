import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/core/observability/owner_query_budget_service.dart';

class OwnerWorkspaceSnapshot {
  const OwnerWorkspaceSnapshot({
    required this.memberCount,
    required this.deviceCount,
    required this.openFeedbackCount,
    required this.openSurveyCount,
    required this.activeChallengeCount,
    required this.generatedAt,
  });

  final int memberCount;
  final int deviceCount;
  final int openFeedbackCount;
  final int openSurveyCount;
  final int activeChallengeCount;
  final DateTime generatedAt;

  bool get isEmpty =>
      memberCount == 0 &&
      deviceCount == 0 &&
      openFeedbackCount == 0 &&
      openSurveyCount == 0 &&
      activeChallengeCount == 0;
}

abstract class OwnerWorkspaceRepository {
  Future<OwnerWorkspaceSnapshot> loadSnapshot(String gymId);
}

class FirestoreOwnerWorkspaceRepository implements OwnerWorkspaceRepository {
  FirestoreOwnerWorkspaceRepository(
    this._firestore, {
    OwnerQueryBudgetService? queryBudgetService,
  }) : _queryBudgetService =
           queryBudgetService ?? OwnerQueryBudgetService.instance;

  final FirebaseFirestore _firestore;
  final OwnerQueryBudgetService _queryBudgetService;
  static const OwnerQueryBudget _snapshotBudget = OwnerQueryBudget(
    maxQueries: 8,
    maxDocsRead: 500,
  );

  @override
  Future<OwnerWorkspaceSnapshot> loadSnapshot(String gymId) async {
    return _queryBudgetService.track<OwnerWorkspaceSnapshot>(
      flow: 'owner.workspace.snapshot',
      budget: _snapshotBudget,
      command: (counter) async {
        final now = DateTime.now();
        final gymRef = _firestore.collection('gyms').doc(gymId);

        final futures = await Future.wait<int>([
          _count(
            gymRef.collection('users').where('role', isEqualTo: 'member'),
            counter: counter,
          ),
          _count(gymRef.collection('devices'), counter: counter),
          _count(
            gymRef.collection('feedback').where('isDone', isEqualTo: false),
            counter: counter,
          ),
          _count(
            gymRef.collection('surveys').where('status', isEqualTo: 'open'),
            counter: counter,
          ),
          _countActiveChallenges(gymId, now, counter: counter),
        ]);

        return OwnerWorkspaceSnapshot(
          memberCount: futures[0],
          deviceCount: futures[1],
          openFeedbackCount: futures[2],
          openSurveyCount: futures[3],
          activeChallengeCount: futures[4],
          generatedAt: now,
        );
      },
    );
  }

  Future<int> _count(
    Query<Map<String, dynamic>> query, {
    required OwnerQueryCounter counter,
  }) async {
    final snapshot = await query.count().get();
    counter.recordQueryResult(docsRead: 1);
    return snapshot.count ?? 0;
  }

  Future<int> _countActiveChallenges(
    String gymId,
    DateTime now, {
    required OwnerQueryCounter counter,
  }) async {
    final weekly = await _countActiveChallengesForPeriod(
      gymId: gymId,
      period: 'weekly',
      now: now,
      counter: counter,
    );
    final monthly = await _countActiveChallengesForPeriod(
      gymId: gymId,
      period: 'monthly',
      now: now,
      counter: counter,
    );
    return weekly + monthly;
  }

  Future<int> _countActiveChallengesForPeriod({
    required String gymId,
    required String period,
    required DateTime now,
    required OwnerQueryCounter counter,
  }) async {
    final nowTs = Timestamp.fromDate(now);
    final snap = await _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('challenges')
        .doc(period)
        .collection('items')
        .where('end', isGreaterThanOrEqualTo: nowTs)
        .get();
    counter.recordQueryResult(docsRead: snap.docs.length);

    var activeCount = 0;
    for (final doc in snap.docs) {
      final data = doc.data();
      final start = _asDateTime(data['start']);
      final end = _asDateTime(data['end']);
      if (start == null || end == null) {
        continue;
      }
      if (!start.isAfter(now) && !end.isBefore(now)) {
        activeCount += 1;
      }
    }
    return activeCount;
  }

  DateTime? _asDateTime(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return null;
  }
}

final ownerWorkspaceRepositoryProvider = Provider<OwnerWorkspaceRepository>((
  ref,
) {
  return FirestoreOwnerWorkspaceRepository(FirebaseFirestore.instance);
});

final ownerWorkspaceSnapshotProvider =
    FutureProvider.family<OwnerWorkspaceSnapshot, String>((ref, gymId) async {
      if (gymId.isEmpty) {
        throw ArgumentError('gymId must not be empty');
      }
      final repo = ref.watch(ownerWorkspaceRepositoryProvider);
      return repo.loadSnapshot(gymId);
    });

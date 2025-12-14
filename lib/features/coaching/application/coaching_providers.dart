import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/features/coaching/data/repositories/coaching_repository_impl.dart';
import 'package:tapem/features/coaching/data/sources/firestore_coaching_source.dart';
import 'package:tapem/features/coaching/domain/models/coach_client_relation.dart';
import 'package:tapem/features/coaching/domain/models/client_coaching_analytics.dart';
import 'package:tapem/features/coaching/domain/repositories/coaching_repository.dart';
import 'package:tapem/features/training_plan/application/training_plan_provider.dart';

final coachingRepositoryProvider = Provider<CoachingRepository>((ref) {
  return CoachingRepositoryImpl(
    FirestoreCoachingSource(FirebaseFirestore.instance),
  );
});

/// Zentrales Repository für Coaching-Beziehungen.
final coachRelationsProvider =
    FutureProvider<List<CoachClientRelation>>((ref) async {
  final authState = ref.watch(authViewStateProvider);
  final userId = authState.userId;

  // ignore: avoid_print
  print(
    '[CoachingProvider] coachRelationsProvider userId=$userId '
    'isCoach=${authState.isCoach} gymCode=${authState.gymCode}',
  );

  if (userId == null) {
    return [];
  }

  final repo = ref.watch(coachingRepositoryProvider);
  try {
    final result = await repo.getRelationsForCoach(coachId: userId);
    // ignore: avoid_print
    print(
      '[CoachingProvider] coachRelationsProvider loaded '
      '${result.length} relations for coachId=$userId',
    );
    return result;
  } catch (e) {
    // ignore: avoid_print
    print(
      '[CoachingProvider] coachRelationsProvider ERROR for userId=$userId -> $e',
    );
    rethrow;
  }
});

final clientRelationsProvider =
    FutureProvider<List<CoachClientRelation>>((ref) async {
  final authState = ref.watch(authViewStateProvider);
  final userId = authState.userId;

  // ignore: avoid_print
  print(
    '[CoachingProvider] clientRelationsProvider userId=$userId '
    'gymCode=${authState.gymCode}',
  );

  if (userId == null) {
    return [];
  }

  final repo = ref.watch(coachingRepositoryProvider);
  try {
    final result = await repo.getRelationsForClient(clientId: userId);
    // ignore: avoid_print
    print(
      '[CoachingProvider] clientRelationsProvider loaded '
      '${result.length} relations for clientId=$userId',
    );
    return result;
  } catch (e) {
    // ignore: avoid_print
    print(
      '[CoachingProvider] clientRelationsProvider ERROR for userId=$userId -> $e',
    );
    rethrow;
  }
});

/// Liste der Coach-IDs für das aktuelle Gym.
final availableCoachIdsProvider =
    FutureProvider<List<String>>((ref) async {
  final authState = ref.watch(authViewStateProvider);
  final userId = authState.userId;
  final gymId = authState.gymCode;

  // ignore: avoid_print
  print(
    '[CoachingProvider] availableCoachIdsProvider userId=$userId '
    'gymId=$gymId',
  );

  if (userId == null || gymId == null || gymId.isEmpty) {
    return [];
  }

  final firestore = FirebaseFirestore.instance;
  try {
    final snapshot = await firestore
        .collection('users')
        .where('coachEnabled', isEqualTo: true)
        .where('gymCodes', arrayContains: gymId)
        .get();
    final ids = snapshot.docs
        .map((doc) => doc.id)
        .where((id) => id != userId)
        .toList(growable: false);
    // ignore: avoid_print
    print(
      '[CoachingProvider] availableCoachIdsProvider loaded '
      '${ids.length} coaches for gymId=$gymId',
    );
    return ids;
  } on FirebaseException catch (e) {
    // ignore: avoid_print
    print(
      '[CoachingProvider] availableCoachIdsProvider FIRESTORE_ERROR '
      'code=${e.code} message=${e.message}',
    );
    rethrow;
  } catch (e) {
    // ignore: avoid_print
    print(
      '[CoachingProvider] availableCoachIdsProvider UNKNOWN_ERROR $e',
    );
    rethrow;
  }
});

/// Liefert einen angezeigten Namen für einen User (Username oder E-Mail, Fallback auf ID).
final userDisplayNameProvider =
    FutureProvider.family<String, String>((ref, String uid) async {
  final firestore = FirebaseFirestore.instance;
  final snap = await firestore.collection('users').doc(uid).get();
  if (!snap.exists) {
    return 'Unbekanntes Mitglied';
  }
  final data = snap.data() ?? {};
  final userName = data['username'] as String?;
  final email = data['email'] as String?;
  if (userName != null && userName.trim().isNotEmpty) {
    return userName;
  }
  if (email != null && email.trim().isNotEmpty) {
    return email;
  }
  return uid;
});

/// Convenience: Name für einen Client.
final clientDisplayNameProvider =
    FutureProvider.family<String, String>((ref, String clientId) async {
  return ref.watch(userDisplayNameProvider(clientId)).maybeWhen(
        data: (value) => value,
        orElse: () => 'Unbekanntes Mitglied',
      );
});

/// Convenience: Name für einen Coach.
final coachDisplayNameProvider =
    FutureProvider.family<String, String>((ref, String coachId) async {
  return ref.watch(userDisplayNameProvider(coachId)).maybeWhen(
        data: (value) => value,
        orElse: () => 'Unbekannter Coach',
      );
});

/// Aggregierte Trainings-Analytics für einen Client (für Coach-Sicht).
final clientCoachingAnalyticsProvider =
    FutureProvider.family<ClientCoachingAnalytics, String>((ref, String clientId) async {
  final authState = ref.watch(authViewStateProvider);
  final gymId = authState.gymCode;

  if (gymId == null || gymId.isEmpty) {
    return ClientCoachingAnalytics.empty();
  }

  final repo = ref.watch(trainingPlanRepositoryProvider);

  try {
    final plans = await repo.getPlans(gymId: gymId, userId: clientId);
    if (plans.isEmpty) {
      return ClientCoachingAnalytics.empty();
    }

    var totalCompletions = 0;
    DateTime? firstCompletedAt;
    DateTime? lastCompletedAt;

    for (final plan in plans) {
      final stats = await repo.getStats(userId: clientId, planId: plan.id);
      totalCompletions += stats.completions;
      final first = stats.firstCompletedAt;
      final last = stats.lastCompletedAt;

      if (first != null &&
          (firstCompletedAt == null || first.isBefore(firstCompletedAt))) {
        firstCompletedAt = first;
      }
      if (last != null &&
          (lastCompletedAt == null || last.isAfter(lastCompletedAt))) {
        lastCompletedAt = last;
      }
    }

    double avgPerWeek = 0;
    if (totalCompletions > 0 && firstCompletedAt != null) {
      final days = DateTime.now().difference(firstCompletedAt).inDays;
      final weeksSpan = (days ~/ 7) + 1;
      avgPerWeek = totalCompletions / weeksSpan;
    }

    // ignore: avoid_print
    print(
      '[CoachingProvider] clientCoachingAnalyticsProvider '
      'clientId=$clientId totalCompletions=$totalCompletions '
      'totalPlans=${plans.length} avgPerWeek=${avgPerWeek.toStringAsFixed(2)}',
    );

    return ClientCoachingAnalytics(
      totalCompletions: totalCompletions,
      totalPlans: plans.length,
      avgSessionsPerWeek: avgPerWeek,
      lastActivity: lastCompletedAt,
    );
  } catch (e) {
    // ignore: avoid_print
    print(
      '[CoachingProvider] clientCoachingAnalyticsProvider ERROR '
      'clientId=$clientId -> $e',
    );
    return ClientCoachingAnalytics.empty();
  }
}
);

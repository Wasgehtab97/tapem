import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tapem/core/observability/owner_action_observability_service.dart';
import 'package:tapem/core/services/admin_audit_logger.dart';
import 'package:tapem/features/challenges/domain/models/challenge.dart';

enum AdminChallengePeriod { weekly, monthly }

enum AdminChallengeGoalType { deviceSets, workoutFrequency }

class ChallengeAdminCreateInput {
  const ChallengeAdminCreateInput({
    required this.gymId,
    required this.actorUid,
    required this.title,
    required this.description,
    required this.xpReward,
    required this.goalType,
    required this.period,
    required this.periodValue,
    required this.year,
    this.deviceIds = const <String>[],
    this.minSets,
    this.targetWorkouts,
    this.durationWeeks = 1,
  });

  final String gymId;
  final String actorUid;
  final String title;
  final String description;
  final List<String> deviceIds;
  final int? minSets;
  final int? targetWorkouts;
  final int durationWeeks;
  final int xpReward;
  final AdminChallengeGoalType goalType;
  final AdminChallengePeriod period;
  final int periodValue;
  final int year;
}

class ChallengeAdminCreateResult {
  const ChallengeAdminCreateResult({required this.challengeId});

  final String challengeId;
}

class ChallengeAdminService {
  ChallengeAdminService({
    FirebaseFirestore? firestore,
    AdminAuditLogger? auditLogger,
    OwnerActionObservabilityService? observability,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auditLogger = auditLogger ?? AdminAuditLogger(),
       _observability =
           observability ?? OwnerActionObservabilityService.instance;

  final FirebaseFirestore _firestore;
  final AdminAuditLogger _auditLogger;
  final OwnerActionObservabilityService _observability;

  Future<ChallengeAdminCreateResult> createChallenge(
    ChallengeAdminCreateInput input,
  ) async {
    _validateInput(input);

    final payload = _buildPayload(input);
    final collection = _collectionForPeriod(
      gymId: input.gymId,
      period: input.period,
    );

    final docRef = await _observability.trackAction(
      action: 'owner.challenges.create',
      command: () => collection.add(payload),
    );

    await _auditLogger.logGymAction(
      gymId: input.gymId,
      action: 'challenge_create',
      actorUid: input.actorUid,
      metadata: <String, dynamic>{
        'challengeType': input.period.name,
        'challengeGoalType': input.goalType.name,
        'challengeId': docRef.id,
        'deviceCount': input.deviceIds.length,
        'xpReward': input.xpReward,
      },
    );

    return ChallengeAdminCreateResult(challengeId: docRef.id);
  }

  void _validateInput(ChallengeAdminCreateInput input) {
    if (input.gymId.trim().isEmpty) {
      throw ArgumentError('gymId must not be empty.');
    }
    if (input.title.trim().isEmpty) {
      throw ArgumentError('title must not be empty.');
    }
    if (input.description.trim().isEmpty) {
      throw ArgumentError('description must not be empty.');
    }
    if (input.xpReward <= 0) {
      throw ArgumentError('xpReward must be > 0.');
    }

    switch (input.goalType) {
      case AdminChallengeGoalType.deviceSets:
        if (input.deviceIds.isEmpty) {
          throw ArgumentError('deviceIds must not be empty.');
        }
        if ((input.minSets ?? 0) <= 0) {
          throw ArgumentError('minSets must be > 0.');
        }
        break;
      case AdminChallengeGoalType.workoutFrequency:
        if (input.period != AdminChallengePeriod.weekly) {
          throw ArgumentError(
            'workoutFrequency challenges only support weekly periods.',
          );
        }
        if ((input.targetWorkouts ?? 0) <= 0) {
          throw ArgumentError('targetWorkouts must be > 0.');
        }
        if (input.durationWeeks != 1 && input.durationWeeks != 4) {
          throw ArgumentError('durationWeeks must be either 1 or 4.');
        }
        break;
    }

    switch (input.period) {
      case AdminChallengePeriod.weekly:
        if (input.periodValue < 1 || input.periodValue > 53) {
          throw ArgumentError('week must be in [1, 53].');
        }
        break;
      case AdminChallengePeriod.monthly:
        if (input.periodValue < 1 || input.periodValue > 12) {
          throw ArgumentError('month must be in [1, 12].');
        }
        break;
    }
  }

  Map<String, dynamic> _buildPayload(ChallengeAdminCreateInput input) {
    final title = input.title.trim();
    final description = input.description.trim();
    final deviceIds = input.deviceIds.toSet().toList(growable: false);

    final DateTime start;
    final DateTime end;
    final payload = <String, dynamic>{
      'title': title,
      'description': description,
      'xpReward': input.xpReward,
      'goalType': input.goalType == AdminChallengeGoalType.workoutFrequency
          ? ChallengeGoalType.workoutDays.toFirestoreValue()
          : ChallengeGoalType.deviceSets.toFirestoreValue(),
    };

    if (input.goalType == AdminChallengeGoalType.workoutFrequency) {
      start = _startOfWeek(input.year, input.periodValue);
      end = start
          .add(Duration(days: input.durationWeeks * 7))
          .subtract(const Duration(milliseconds: 1));
      payload['startWeek'] = input.periodValue;
      payload['endWeek'] = _isoWeekNumber(end);
      payload['durationWeeks'] = input.durationWeeks;
      payload['targetWorkouts'] = input.targetWorkouts;
      payload['deviceIds'] = <String>[];
      payload['minSets'] = 0;
    } else if (input.period == AdminChallengePeriod.weekly) {
      start = _startOfWeek(input.year, input.periodValue);
      end = start
          .add(const Duration(days: 7))
          .subtract(const Duration(milliseconds: 1));
      payload['startWeek'] = input.periodValue;
      payload['endWeek'] = input.periodValue;
      payload['deviceIds'] = deviceIds;
      payload['minSets'] = input.minSets;
      payload['durationWeeks'] = 1;
      payload['targetWorkouts'] = 0;
    } else {
      start = DateTime(input.year, input.periodValue, 1);
      end = DateTime(
        input.year,
        input.periodValue + 1,
        1,
      ).subtract(const Duration(milliseconds: 1));
      payload['startMonth'] = input.periodValue;
      payload['endMonth'] = input.periodValue;
      payload['deviceIds'] = deviceIds;
      payload['minSets'] = input.minSets;
      payload['durationWeeks'] = 1;
      payload['targetWorkouts'] = 0;
    }

    payload['start'] = Timestamp.fromDate(start);
    payload['end'] = Timestamp.fromDate(end);
    return payload;
  }

  CollectionReference<Map<String, dynamic>> _collectionForPeriod({
    required String gymId,
    required AdminChallengePeriod period,
  }) {
    final periodId = period == AdminChallengePeriod.weekly
        ? 'weekly'
        : 'monthly';
    return _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('challenges')
        .doc(periodId)
        .collection('items');
  }

  DateTime _startOfWeek(int year, int week) {
    final jan4 = DateTime(year, 1, 4);
    final startOfWeek1 = jan4.subtract(Duration(days: jan4.weekday - 1));
    return startOfWeek1.add(Duration(days: (week - 1) * 7));
  }

  int _isoWeekNumber(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final thursday = normalized.add(Duration(days: 4 - normalized.weekday));
    final firstThursday = DateTime(thursday.year, 1, 4);
    final firstWeekStart = firstThursday.subtract(
      Duration(days: firstThursday.weekday - 1),
    );
    return (thursday.difference(firstWeekStart).inDays / 7).floor() + 1;
  }
}

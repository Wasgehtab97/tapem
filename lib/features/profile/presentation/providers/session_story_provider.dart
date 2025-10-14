import 'package:flutter/foundation.dart';
import 'package:tapem/core/providers/profile_provider.dart';
import 'package:tapem/features/rank/domain/services/level_service.dart';
import 'package:tapem/features/training_details/data/repositories/session_repository_impl.dart';
import 'package:tapem/features/training_details/data/session_meta_source.dart';
import 'package:tapem/features/training_details/data/sources/firestore_session_source.dart';
import 'package:tapem/features/training_details/domain/models/session.dart';
import 'package:tapem/features/training_details/domain/repositories/session_repository.dart';

class SessionStoryProvider extends ChangeNotifier {
  SessionStoryProvider({
    SessionRepository? repository,
    required ProfileProvider profileProvider,
  })  : _repository =
            repository ?? SessionRepositoryImpl(FirestoreSessionSource(), SessionMetaSource()),
        _profileProvider = profileProvider;

  final SessionRepository _repository;
  final ProfileProvider _profileProvider;

  bool _isLoading = false;
  String? _error;
  SessionStoryData? _story;

  bool get isLoading => _isLoading;
  String? get error => _error;
  SessionStoryData? get story => _story;

  Future<void> load({
    required String userId,
    required String gymId,
    required DateTime date,
    String? gymName,
  }) async {
    if (_isLoading) {
      return;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final sessions =
          await _repository.getSessionsForDate(userId: userId, date: date);
      final data = _buildStory(
        sessions: sessions,
        date: date,
        gymId: gymId,
        gymName: gymName,
      );
      _story = data;
    } catch (e, st) {
      _error = e.toString();
      debugPrint('SessionStoryProvider.load error: $e');
      debugPrintStack(stackTrace: st);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  SessionStoryData _buildStory({
    required List<Session> sessions,
    required DateTime date,
    required String gymId,
    String? gymName,
  }) {
    final totals = _calculateTotals(sessions);
    final badges = _buildBadges(
      sessions: sessions,
      gymId: gymId,
      date: date,
    );
    final xp = sessions.isEmpty ? 0 : LevelService.xpPerSession;
    return SessionStoryData(
      date: DateTime(date.year, date.month, date.day),
      xp: xp,
      totalSets: totals.sets,
      totalDuration: totals.duration,
      totalVolumeKg: totals.volumeKg,
      badges: badges,
      gymName: gymName,
    );
  }

  _StoryTotals _calculateTotals(List<Session> sessions) {
    var sets = 0;
    double volume = 0;
    DateTime? earliest;
    DateTime? latest;

    for (final session in sessions) {
      final start = session.startTime ?? session.timestamp;
      DateTime? end;
      if (session.endTime != null) {
        end = session.endTime;
      } else if (session.startTime != null && session.durationMs != null) {
        end = session.startTime!.add(Duration(milliseconds: session.durationMs!));
      } else if (session.durationMs != null) {
        end = start.add(Duration(milliseconds: session.durationMs!));
      } else {
        end = session.timestamp;
      }

      if (earliest == null || start.isBefore(earliest)) {
        earliest = start;
      }
      if (latest == null || end.isAfter(latest)) {
        latest = end;
      }

      for (final set in session.sets) {
        sets += 1;
        volume += _volumeForSet(set.weight, set.reps, set.isBodyweight);
        if (set.dropWeightKg != null && set.dropReps != null && set.dropReps! > 0) {
          sets += 1;
          volume += _volumeForSet(set.dropWeightKg!, set.dropReps!, false);
        }
      }
    }

    final duration =
        earliest != null && latest != null ? latest.difference(earliest) : Duration.zero;
    return _StoryTotals(sets: sets, volumeKg: volume, duration: duration);
  }

  double _volumeForSet(double weight, int reps, bool isBodyweight) {
    if (reps <= 0) {
      return 0;
    }
    if (isBodyweight && weight <= 0) {
      return 0;
    }
    return weight * reps;
  }

  List<SessionStoryBadge> _buildBadges({
    required List<Session> sessions,
    required String gymId,
    required DateTime date,
  }) {
    final day = DateTime(date.year, date.month, date.day);
    final badges = <SessionStoryBadge>[];
    final seenFirstDevice = <String>{};
    final seenFirstExercise = <String>{};
    final bestE1rmToday = <String, double>{};
    final labelByKey = <String, String>{};

    for (final session in sessions) {
      final deviceKey = _aggregateKey(gymId, session.deviceId, null);
      labelByKey[deviceKey] = session.deviceName;
      final firstDevice =
          _profileProvider.firstUsageForDevice(gymId, session.deviceId);
      if (firstDevice != null && _isSameDay(firstDevice, day) &&
          seenFirstDevice.add(deviceKey)) {
        badges.add(
          SessionStoryBadge(
            type: SessionStoryBadgeType.firstDevice,
            name: session.deviceName,
            isExercise: false,
          ),
        );
      }

      final exerciseId = session.exerciseId;
      final hasExercise = exerciseId != null && exerciseId.isNotEmpty;
      if (hasExercise) {
        final exerciseKey = _aggregateKey(gymId, session.deviceId, exerciseId);
        labelByKey[exerciseKey] = session.deviceName;
        final firstExercise = _profileProvider.firstUsageForExercise(
          gymId,
          session.deviceId,
          exerciseId,
        );
        if (firstExercise != null && _isSameDay(firstExercise, day) &&
            seenFirstExercise.add(exerciseKey)) {
          badges.add(
            SessionStoryBadge(
              type: SessionStoryBadgeType.firstExercise,
              name: session.deviceName,
              isExercise: true,
            ),
          );
        }
      }

      for (final set in session.sets) {
        final e1rm = _estimateE1rm(set.weight, set.reps, set.isBodyweight);
        if (e1rm != null) {
          _updateBest(bestE1rmToday, deviceKey, e1rm);
          if (hasExercise) {
            _updateBest(
              bestE1rmToday,
              _aggregateKey(gymId, session.deviceId, exerciseId),
              e1rm,
            );
          }
        }
        if (set.dropWeightKg != null && set.dropReps != null) {
          final dropE1rm = _estimateE1rm(set.dropWeightKg, set.dropReps, false);
          if (dropE1rm != null) {
            _updateBest(bestE1rmToday, deviceKey, dropE1rm);
            if (hasExercise) {
              _updateBest(
                bestE1rmToday,
                _aggregateKey(gymId, session.deviceId, exerciseId),
                dropE1rm,
              );
            }
          }
        }
      }
    }

    final devicesWithExercisePr = <String>{};
    final entries = bestE1rmToday.entries.toList()
      ..sort((a, b) {
        final aParts = _splitKey(a.key);
        final bParts = _splitKey(b.key);
        final aHasExercise = aParts.exerciseId != null;
        final bHasExercise = bParts.exerciseId != null;
        if (aHasExercise == bHasExercise) {
          return 0;
        }
        return aHasExercise ? -1 : 1;
      });

    for (final entry in entries) {
      final key = entry.key;
      final value = entry.value;
      if (value <= 0) {
        continue;
      }
      final parts = _splitKey(key);
      final previous = _profileProvider.bestE1rmBefore(
        parts.gymId,
        parts.deviceId,
        parts.exerciseId,
        day,
      );
      if (previous == null || value <= previous) {
        continue;
      }
      final hasExercise = parts.exerciseId != null;
      if (!hasExercise && devicesWithExercisePr.contains(parts.deviceId)) {
        continue;
      }
      if (hasExercise) {
        devicesWithExercisePr.add(parts.deviceId);
      }
      final label = labelByKey[key] ??
          labelByKey[_aggregateKey(parts.gymId, parts.deviceId, null)] ??
          parts.deviceId;
      badges.add(
        SessionStoryBadge(
          type: SessionStoryBadgeType.recordE1rm,
          name: label,
          metricKg: value,
          isExercise: hasExercise,
        ),
      );
    }

    return badges;
  }

  void _updateBest(Map<String, double> map, String key, double value) {
    final current = map[key];
    if (current == null || value > current) {
      map[key] = value;
    }
  }

  bool _isSameDay(DateTime timestamp, DateTime reference) {
    return timestamp.year == reference.year &&
        timestamp.month == reference.month &&
        timestamp.day == reference.day;
  }

  double? _estimateE1rm(double? weight, int? reps, bool isBodyweight) {
    if (weight == null || reps == null) {
      return null;
    }
    if (reps <= 0 || weight <= 0) {
      return null;
    }
    if (isBodyweight && weight <= 0) {
      return null;
    }
    return weight * (1 + reps / 30.0);
  }

  String _aggregateKey(String gymId, String deviceId, String? exerciseId) {
    final trimmed = exerciseId?.trim();
    final normalized = (trimmed == null || trimmed.isEmpty) ? '' : trimmed;
    return '$gymId|$deviceId|$normalized';
  }

  _AggregateKey _splitKey(String key) {
    final parts = key.split('|');
    return _AggregateKey(
      gymId: parts.isNotEmpty ? parts[0] : '',
      deviceId: parts.length > 1 ? parts[1] : '',
      exerciseId: parts.length > 2 && parts[2].isNotEmpty ? parts[2] : null,
    );
  }
}

class SessionStoryData {
  SessionStoryData({
    required this.date,
    required this.xp,
    required this.totalSets,
    required this.totalDuration,
    required this.totalVolumeKg,
    required this.badges,
    this.gymName,
  });

  final DateTime date;
  final int xp;
  final int totalSets;
  final Duration totalDuration;
  final double totalVolumeKg;
  final List<SessionStoryBadge> badges;
  final String? gymName;
}

enum SessionStoryBadgeType { firstDevice, firstExercise, recordE1rm }

class SessionStoryBadge {
  SessionStoryBadge({
    required this.type,
    required this.name,
    this.metricKg,
    required this.isExercise,
  });

  final SessionStoryBadgeType type;
  final String name;
  final double? metricKg;
  final bool isExercise;
}

class _StoryTotals {
  _StoryTotals({
    required this.sets,
    required this.volumeKg,
    required this.duration,
  });

  final int sets;
  final double volumeKg;
  final Duration duration;
}

class _AggregateKey {
  _AggregateKey({
    required this.gymId,
    required this.deviceId,
    required this.exerciseId,
  });

  final String gymId;
  final String deviceId;
  final String? exerciseId;
}

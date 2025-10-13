import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'session_story_data.dart';
import '../data/exercise_muscle_map.dart';

@immutable
class SessionLogEntry {
  final Map<String, dynamic> data;

  const SessionLogEntry(this.data);

  String? get deviceId => _asString(data['deviceId']);
  String? get exerciseId => _asString(data['exerciseId']);

  static String? _asString(dynamic value) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
  }
}

class SessionXpBreakdown {
  final double totalXp;
  final double baseXp;
  final double bonusXp;
  final Map<String, double> perMuscle;
  final Map<String, double> perDevice;

  const SessionXpBreakdown({
    required this.totalXp,
    required this.baseXp,
    required this.bonusXp,
    required this.perMuscle,
    required this.perDevice,
  });
}

class SessionXpCalculator {
  static const Map<SessionStoryBadgeType, int> _bonusValues = {
    SessionStoryBadgeType.estimatedOneRepMax: 10,
    SessionStoryBadgeType.volume: 5,
    SessionStoryBadgeType.firstDevice: 3,
    SessionStoryBadgeType.firstExercise: 3,
  };

  static SessionXpBreakdown compute({
    required List<SessionLogEntry> logs,
    required List<SessionStoryPrEvent> events,
  }) {
    double baseXp = 0;
    double bonusXp = 0;
    final perDevice = <String, double>{};
    final perMuscle = <String, double>{};

    for (final log in logs) {
      final payload = log.data;
      final deviceId = log.deviceId;
      final exerciseId = log.exerciseId;
      final muscles = _resolveMuscles(exerciseId, payload);
      final sets = _extractSets(payload);
      var logXp = 0.0;
      for (final set in sets) {
        final amount = _computeSetXp(set);
        if (amount <= 0) continue;
        baseXp += amount;
        logXp += amount;
        if (deviceId != null) {
          perDevice.update(deviceId, (value) => value + amount,
              ifAbsent: () => amount);
        }
        if (muscles.isNotEmpty) {
          final share = amount / muscles.length;
          for (final muscleId in muscles) {
            perMuscle.update(muscleId, (value) => value + share,
                ifAbsent: () => share);
          }
        }
      }
      if (logXp <= 0 && deviceId != null) {
        perDevice.putIfAbsent(deviceId, () => 0.0);
      }
    }

    for (final event in events) {
      final bonus = _bonusValues[event.type];
      if (bonus == null) continue;
      bonusXp += bonus;
      final deviceId = event.deviceId;
      if (deviceId != null && deviceId.isNotEmpty) {
        perDevice.update(deviceId, (value) => value + bonus,
            ifAbsent: () => bonus.toDouble());
      }
      final exerciseMuscles = event.exerciseId != null
          ? ExerciseMuscleMap.lookup(event.exerciseId!)
          : const <String>[];
      if (exerciseMuscles.isNotEmpty) {
        final share = bonus / exerciseMuscles.length;
        for (final muscle in exerciseMuscles) {
          perMuscle.update(muscle, (value) => value + share,
              ifAbsent: () => share);
        }
      }
    }

    final roundedMuscles = perMuscle.map((key, value) => MapEntry(
        key, double.parse(value.toStringAsFixed(2))));
    final roundedDevices = perDevice.map((key, value) => MapEntry(
        key, double.parse(value.toStringAsFixed(2))));

    return SessionXpBreakdown(
      totalXp: double.parse((baseXp + bonusXp).toStringAsFixed(2)),
      baseXp: double.parse(baseXp.toStringAsFixed(2)),
      bonusXp: double.parse(bonusXp.toStringAsFixed(2)),
      perMuscle: roundedMuscles,
      perDevice: roundedDevices,
    );
  }

  static List<Map<String, dynamic>> _extractSets(Map<String, dynamic> payload) {
    final sets = <Map<String, dynamic>>[];
    void pushSet({
      required num weight,
      required int reps,
      bool isBodyweight = false,
      num? rir,
    }) {
      sets.add({
        'weight': weight,
        'reps': reps,
        'isBodyweight': isBodyweight,
        'rir': rir,
      });
    }

    num? _toNumber(dynamic value) {
      if (value == null) return null;
      if (value is num && value.isFinite) return value;
      if (value is String && value.trim().isNotEmpty) {
        final parsed = num.tryParse(value);
        if (parsed != null && parsed.isFinite) return parsed;
      }
      return null;
    }

    final reps = _toNumber(
        payload['reps'] ?? payload['repCount'] ?? payload['repetitions']);
    final weight = _toNumber(
            payload['weight'] ?? payload['weightKg'] ?? payload['loadKg']) ??
        0;
    final rir = _toNumber(
        payload['rir'] ?? payload['targetRir'] ?? payload['estimatedRir']);
    final isBodyweight = payload['isBodyweight'] == true ||
        payload['loadType'] == 'bodyweight';
    if (reps != null && reps > 0) {
      pushSet(weight: weight, reps: reps.toInt(), isBodyweight: isBodyweight, rir: rir);
    }

    final drops = payload['drops'] ?? payload['dropSets'];
    if (drops is Iterable) {
      for (final entry in drops) {
        if (entry is Map) {
          final dropReps = _toNumber(entry['reps'] ?? entry['repCount']);
          final dropWeight = _toNumber(entry['weight'] ?? entry['weightKg'] ?? entry['loadKg']);
          if (dropReps != null && dropReps > 0) {
            pushSet(
              weight: dropWeight ?? 0,
              reps: dropReps.toInt(),
              isBodyweight: isBodyweight,
              rir: rir,
            );
          }
        }
      }
    }

    return sets;
  }

  static double _computeSetXp(Map<String, dynamic> set) {
    final reps = (set['reps'] as num?)?.toDouble();
    if (reps == null || reps <= 0) return 0;
    final isBodyweight = set['isBodyweight'] == true;
    final rawWeight = (set['weight'] as num?)?.toDouble() ?? 0;
    final weight = (!isBodyweight && rawWeight > 0) ? rawWeight : 0;
    var intensity = reps + weight / 10.0;
    if (weight == 0) {
      intensity += 2;
    }
    var multiplier = 1.0;
    final rir = (set['rir'] as num?)?.toDouble();
    if (rir != null) {
      final normalized = _clamp(10 - _clamp(rir, 0, 5), 0, 10) / 5.0;
      multiplier = _clamp(0.5 + normalized, 0.5, 1.5);
    }
    final raw = intensity * 2 * multiplier;
    return math.max(1, raw.roundToDouble());
  }

  static double _clamp(num value, num min, num max) {
    return math.min(math.max(value.toDouble(), min.toDouble()), max.toDouble());
  }

  static List<String> _resolveMuscles(
      String? exerciseId, Map<String, dynamic> payload) {
    final muscles = <String>{};
    if (exerciseId != null && exerciseId.isNotEmpty) {
      muscles.addAll(ExerciseMuscleMap.lookup(exerciseId));
    }
    void addList(dynamic raw) {
      if (raw is Iterable) {
        for (final entry in raw) {
          if (entry is String && entry.trim().isNotEmpty) {
            muscles.add(entry.trim());
          }
        }
      }
    }

    addList(payload['primaryMuscleGroupIds']);
    addList(payload['secondaryMuscleGroupIds']);
    addList(payload['muscleGroupIds']);
    return muscles.toList();
  }
}

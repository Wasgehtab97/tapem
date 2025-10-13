import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../domain/session_story_data.dart';
import '../domain/session_xp_calculator.dart';

class SessionStoryRepository {
  final FirebaseFirestore _firestore;
  final Map<String, String> _deviceNameCache = {};
  final Map<String, String> _exerciseNameCache = {};

  SessionStoryRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<SessionStoryData> loadStory({
    required String userId,
    required String sessionId,
  }) async {
    final sessionRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('sessions')
        .doc(sessionId);
    final sessionSnap = await _getDocumentPreferCache(sessionRef);
    if (!sessionSnap.exists) {
      throw StateError('Session $sessionId not found');
    }
    final data = sessionSnap.data() ?? <String, dynamic>{};
    final gymId = (data['gymId'] as String?) ?? '';
    final summary = Map<String, dynamic>.from(
        (data['summary'] as Map<String, dynamic>?) ?? {});
    final occurredAt = _resolveOccurredAt(data);

    final prEvents = await _fetchPrEvents(userId: userId, sessionId: sessionId);
    final logs = await _fetchSessionLogs(
      userId: userId,
      sessionId: sessionId,
      gymId: gymId,
    );
    final xpBreakdown = SessionXpCalculator.compute(
      logs: logs,
      events: prEvents,
    );

    final xpTotal = summary['xpTotal'] is num
        ? (summary['xpTotal'] as num).toDouble()
        : xpBreakdown.totalXp;
    final baseXp = xpBreakdown.baseXp;
    final bonusXp = xpBreakdown.bonusXp;

    final topMuscles = xpBreakdown.perMuscle.entries
        .toList()
        ..sort((a, b) => b.value.compareTo(a.value));
    final muscles = topMuscles
        .take(3)
        .map((entry) => SessionStoryMuscle(
              id: entry.key,
              displayName: _formatMuscle(entry.key),
              xp: entry.value,
            ))
        .toList();

    final badges = <SessionStoryBadge>[];
    for (final event in prEvents) {
      final badge = await _buildBadge(event, gymId: gymId);
      if (badge != null) {
        badges.add(badge);
      }
    }

    final gymName = await _resolveGymName(gymId);

    return SessionStoryData(
      sessionId: sessionId,
      userId: userId,
      gymId: gymId,
      gymName: gymName,
      occurredAt: occurredAt,
      xpTotal: xpTotal,
      baseXp: baseXp,
      bonusXp: bonusXp,
      setCount: (summary['setCount'] as num?)?.toInt() ?? 0,
      exerciseCount: (summary['exerciseCount'] as num?)?.toInt() ?? 0,
      totalVolume: (summary['totalVolume'] as num?)?.toDouble() ?? 0,
      durationMinutes: (summary['durationMin'] as num?)?.toDouble() ?? 0,
      badges: badges,
      muscles: muscles,
    );
  }

  Future<List<SessionStoryPrEvent>> _fetchPrEvents({
    required String userId,
    required String sessionId,
  }) async {
    final query = await _firestore
        .collection('users')
        .doc(userId)
        .collection('prEvents')
        .where('sessionId', isEqualTo: sessionId)
        .orderBy('occurredAt', descending: false)
        .get(const GetOptions(source: Source.serverAndCache));
    return query.docs.map((doc) => _mapPrEvent(doc)).whereType<SessionStoryPrEvent>().toList();
  }

  SessionStoryPrEvent? _mapPrEvent(
      QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final type = _badgeTypeFromString(data['type'] as String?);
    if (type == null) return null;
    return SessionStoryPrEvent(
      id: doc.id,
      type: type,
      deviceId: data['deviceId'] as String?,
      exerciseId: data['exerciseId'] as String?,
      value: (data['value'] as num?)?.toDouble(),
      previousBest: (data['previousBest'] as num?)?.toDouble(),
      delta: (data['delta'] as num?)?.toDouble(),
      unit: data['unit'] as String?,
    );
  }

  Future<List<SessionLogEntry>> _fetchSessionLogs({
    required String userId,
    required String sessionId,
    required String gymId,
  }) async {
    final query = await _firestore
        .collectionGroup('logs')
        .where('sessionId', isEqualTo: sessionId)
        .where('userId', isEqualTo: userId)
        .get(const GetOptions(source: Source.serverAndCache));
    final docs = query.docs.where((doc) {
      if (gymId.isEmpty) return true;
      return doc.reference.path.contains('/gyms/$gymId/');
    }).toList();
    return docs.map((doc) => SessionLogEntry(doc.data())).toList();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _getDocumentPreferCache(
      DocumentReference<Map<String, dynamic>> ref) async {
    try {
      final cached = await ref.get(const GetOptions(source: Source.cache));
      if (cached.exists) {
        return cached;
      }
    } catch (_) {
      // cache miss
    }
    return ref.get();
  }

  DateTime _resolveOccurredAt(Map<String, dynamic> data) {
    final endAt = data['endAt'];
    if (endAt is Timestamp) return endAt.toDate();
    final updatedAt = data['updatedAt'];
    if (updatedAt is Timestamp) return updatedAt.toDate();
    return DateTime.now();
  }

  Future<String?> _resolveGymName(String gymId) async {
    if (gymId.isEmpty) return null;
    try {
      final doc = await _getDocumentPreferCache(
        _firestore.collection('gyms').doc(gymId),
      );
      final data = doc.data();
      final name = data?['name'];
      if (name is String && name.trim().isNotEmpty) {
        return name.trim();
      }
    } catch (_) {
      // ignore lookup errors
    }
    return null;
  }

  Future<SessionStoryBadge?> _buildBadge(SessionStoryPrEvent event,
      {required String gymId}) async {
    switch (event.type) {
      case SessionStoryBadgeType.firstDevice:
        final resolved = await _resolveDeviceName(gymId, event.deviceId);
        final label = resolved ?? event.deviceId ?? 'Device';
        return SessionStoryBadge(
          type: event.type,
          label: label,
          icon: Icons.fitness_center,
        );
      case SessionStoryBadgeType.firstExercise:
        final resolved = await _resolveExerciseName(gymId, event);
        final label = resolved ?? event.exerciseId ?? 'Exercise';
        return SessionStoryBadge(
          type: event.type,
          label: label,
          icon: Icons.schedule,
        );
      case SessionStoryBadgeType.estimatedOneRepMax:
        final value = event.value;
        return SessionStoryBadge(
          type: event.type,
          label: '1RM ${_formatNumber(value)}',
          deltaLabel: _formatDelta(event.delta, event.unit ?? 'kg'),
          icon: Icons.military_tech,
          value: value,
          delta: event.delta,
          unit: event.unit,
        );
      case SessionStoryBadgeType.volume:
        final value = event.value;
        return SessionStoryBadge(
          type: event.type,
          label: 'Vol ${_formatNumber(value)} ${event.unit ?? 'kg'}',
          deltaLabel: _formatDelta(event.delta, event.unit ?? 'kg'),
          icon: Icons.stacked_line_chart,
          value: value,
          delta: event.delta,
          unit: event.unit,
        );
    }
  }

  SessionStoryBadgeType? _badgeTypeFromString(String? raw) {
    switch (raw) {
      case 'first_device':
        return SessionStoryBadgeType.firstDevice;
      case 'first_exercise':
        return SessionStoryBadgeType.firstExercise;
      case 'e1rm':
        return SessionStoryBadgeType.estimatedOneRepMax;
      case 'volume':
        return SessionStoryBadgeType.volume;
    }
    return null;
  }

  Future<String?> _resolveDeviceName(String gymId, String? deviceId) async {
    if (gymId.isEmpty || deviceId == null || deviceId.isEmpty) {
      return null;
    }
    final cacheKey = '$gymId::$deviceId';
    if (_deviceNameCache.containsKey(cacheKey)) {
      return _deviceNameCache[cacheKey];
    }
    try {
      final doc = await _getDocumentPreferCache(
        _firestore.collection('gyms').doc(gymId).collection('devices').doc(deviceId),
      );
      final data = doc.data();
      final name = data?['name'];
      if (name is String && name.trim().isNotEmpty) {
        final trimmed = name.trim();
        _deviceNameCache[cacheKey] = trimmed;
        return trimmed;
      }
    } catch (_) {
      // ignore lookup errors
    }
    return null;
  }

  Future<String?> _resolveExerciseName(
      String gymId, SessionStoryPrEvent event) async {
    final exerciseId = event.exerciseId;
    if (exerciseId == null || exerciseId.isEmpty) {
      return null;
    }
    final cacheKey = '$gymId::${event.deviceId ?? ''}::$exerciseId';
    if (_exerciseNameCache.containsKey(cacheKey)) {
      return _exerciseNameCache[cacheKey];
    }
    try {
      if (event.deviceId != null && event.deviceId!.isNotEmpty) {
        final doc = await _getDocumentPreferCache(
          _firestore
              .collection('gyms')
              .doc(gymId)
              .collection('devices')
              .doc(event.deviceId)
              .collection('exercises')
              .doc(exerciseId),
        );
        final data = doc.data();
        final name = data?['name'];
        if (name is String && name.trim().isNotEmpty) {
          final trimmed = name.trim();
          _exerciseNameCache[cacheKey] = trimmed;
          return trimmed;
        }
      }
    } catch (_) {
      // ignore lookup errors
    }
    return null;
  }

  String _formatMuscle(String id) {
    if (id.trim().isEmpty) {
      return 'Muscle';
    }
    final words = id.replaceAll('_', ' ').split(' ');
    return words
        .map((word) =>
            word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  String? _formatDelta(double? delta, String unit) {
    if (delta == null) return null;
    final value = delta >= 0 ? '+${_formatNumber(delta)}' : _formatNumber(delta);
    return '$value $unit';
  }

  String _formatNumber(double? value) {
    if (value == null) return '0';
    if (value.abs() >= 100) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }
}

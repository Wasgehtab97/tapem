import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class StoryAnalyticsService {
  StoryAnalyticsService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _stories(String userId) =>
      _firestore.collection('users').doc(userId).collection('stories');

  DocumentReference<Map<String, dynamic>> _metrics(String userId) =>
      _firestore.collection('users').doc(userId).collection('storyMetrics').doc('summary');

  Future<void> markTimelineOpened(String userId) async {
    if (userId.isEmpty) return;
    try {
      await _metrics(userId).set({
        'timelineOpenCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      }, setOptions);
    } catch (error, stack) {
      debugPrint('StoryAnalyticsService.markTimelineOpened error: $error\n$stack');
    }
  }

  Future<void> trackStoryViewed({
    required String userId,
    required String sessionId,
  }) async {
    if (userId.isEmpty || sessionId.isEmpty) return;
    try {
      final now = FieldValue.serverTimestamp();
      await Future.wait([
        _stories(userId).doc(sessionId).set({
          'lastViewedAt': now,
          'viewCount': FieldValue.increment(1),
        }, setOptions),
        _metrics(userId).set({
          'storyShownCount': FieldValue.increment(1),
          'updatedAt': now,
        }, setOptions),
      ]);
    } catch (error, stack) {
      debugPrint('StoryAnalyticsService.trackStoryViewed error: $error\n$stack');
    }
  }

  Future<void> trackStoryShared({
    required String userId,
    required String sessionId,
    String? target,
  }) async {
    if (userId.isEmpty || sessionId.isEmpty) return;
    try {
      final now = FieldValue.serverTimestamp();
      await Future.wait([
        _stories(userId).doc(sessionId).set({
          'lastSharedAt': now,
          'shareCount': FieldValue.increment(1),
          if (target != null && target.isNotEmpty) 'lastShareTarget': target,
        }, setOptions),
        _metrics(userId).set({
          'shareCount': FieldValue.increment(1),
          'updatedAt': now,
        }, setOptions),
      ]);
    } catch (error, stack) {
      debugPrint('StoryAnalyticsService.trackStoryShared error: $error\n$stack');
    }
  }

  Future<void> trackStorySaved({
    required String userId,
    required String sessionId,
  }) async {
    if (userId.isEmpty || sessionId.isEmpty) return;
    try {
      await _stories(userId).doc(sessionId).set({
        'lastSavedAt': FieldValue.serverTimestamp(),
      }, setOptions);
    } catch (error, stack) {
      debugPrint('StoryAnalyticsService.trackStorySaved error: $error\n$stack');
    }
  }

  SetOptions get setOptions => SetOptions(merge: true);
}

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/session_story_repository.dart';
import 'domain/session_story_data.dart';

class SessionStoryController extends ChangeNotifier {
  final SessionStoryRepository _repository;
  final FirebaseFirestore _firestore;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  String? _userId;
  String? _gymId;
  SessionStoryData? _pendingStory;
  String? _lastSeenSessionId;
  SharedPreferences? _prefs;
  final Set<String> _inFlightSessions = <String>{};

  SessionStoryController({
    FirebaseFirestore? firestore,
    SessionStoryRepository? repository,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _repository =
            repository ?? SessionStoryRepository(firestore: firestore);

  SessionStoryData? get pendingStory => _pendingStory;
  bool get hasPendingStory => _pendingStory != null;
  String? get lastSeenSessionId => _lastSeenSessionId;

  void updateContext({String? userId, String? gymId}) {
    if (_userId == userId && _gymId == gymId) {
      return;
    }
    _userId = userId;
    _gymId = gymId;
    _lastSeenSessionId = null;
    _loadLastSeen();
    _resubscribe();
  }

  Future<void> _loadLastSeen() async {
    final userId = _userId;
    if (userId == null) {
      _lastSeenSessionId = null;
      return;
    }
    final prefs = await _ensurePrefs();
    _lastSeenSessionId = prefs.getString(_prefsKey(userId));
  }

  void _resubscribe() {
    _subscription?.cancel();
    _subscription = null;
    final userId = _userId;
    if (userId == null) {
      return;
    }
    final query = _firestore
        .collection('users')
        .doc(userId)
        .collection('sessions')
        .where('status', isEqualTo: 'closed')
        .orderBy('endAt', descending: true)
        .limit(5);
    _subscription = query
        .snapshots(includeMetadataChanges: true)
        .listen(_handleSnapshot, onError: (Object error) {
      debugPrint('SessionStoryController snapshot error: $error');
    });
  }

  void _handleSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
    if (snapshot.docs.isEmpty) {
      return;
    }
    for (final doc in snapshot.docs) {
      if (doc.metadata.hasPendingWrites) {
        continue;
      }
      final sessionId = doc.id;
      debugPrint('📸 [StoryController] snapshot detected sessionId=$sessionId');
      if (sessionId == _lastSeenSessionId) {
        continue;
      }
      if (_pendingStory != null && _pendingStory!.sessionId == sessionId) {
        continue;
      }
      if (_inFlightSessions.contains(sessionId)) {
        continue;
      }
      debugPrint('📸 [StoryController] queue story load for sessionId=$sessionId');
      _prepareStory(sessionId);
    }
  }

  void _prepareStory(String sessionId) {
    final userId = _userId;
    if (userId == null) return;
    _inFlightSessions.add(sessionId);
    debugPrint('📸 [StoryController] prepare story sessionId=$sessionId');
    unawaited(_loadAndQueue(sessionId));
  }

  Future<void> _loadAndQueue(String sessionId) async {
    try {
      final userId = _userId;
      if (userId == null) return;
      for (var attempt = 0; attempt < 5; attempt++) {
        debugPrint(
          '📸 [StoryController] load attempt ${attempt + 1} for sessionId=$sessionId',
        );
        final story = await _repository.loadStory(
          userId: userId,
          sessionId: sessionId,
        );
        final ready = story.xpTotal > 0 || story.badges.isNotEmpty || attempt >= 3;
        if (ready) {
          _pendingStory = story;
          notifyListeners();
          debugPrint(
            '📸 [StoryController] story ready sessionId=${story.sessionId} xp=${story.xpTotal} badges=${story.badges.length}',
          );
          return;
        }
        await Future<void>.delayed(Duration(seconds: attempt < 2 ? 3 : 5));
      }
    } catch (error, stack) {
      debugPrint('SessionStoryController load error: $error\n$stack');
      debugPrint('❌ [StoryController] failed to load sessionId=$sessionId');
    } finally {
      _inFlightSessions.remove(sessionId);
    }
  }

  SessionStoryData? consumePending({bool markSeen = true}) {
    final story = _pendingStory;
    if (story == null) {
      return null;
    }
    _pendingStory = null;
    if (markSeen) {
      unawaited(setSeen(story.sessionId));
    }
    debugPrint(
      '📸 [StoryController] consume story sessionId=${story.sessionId} markSeen=$markSeen',
    );
    return story;
  }

  Future<void> setSeen(String sessionId) async {
    final userId = _userId;
    if (userId == null) return;
    _lastSeenSessionId = sessionId;
    final prefs = await _ensurePrefs();
    await prefs.setString(_prefsKey(userId), sessionId);
  }

  Future<SessionStoryData> loadStoryById(String sessionId) async {
    final userId = _userId;
    if (userId == null) {
      throw StateError('User context missing');
    }
    return _repository.loadStory(userId: userId, sessionId: sessionId);
  }

  void requestStory(String sessionId) {
    if (sessionId.isEmpty) {
      return;
    }
    if (_pendingStory?.sessionId == sessionId) {
      return;
    }
    if (_inFlightSessions.contains(sessionId)) {
      return;
    }
    _prepareStory(sessionId);
  }

  Future<SharedPreferences> _ensurePrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  String _prefsKey(String userId) => 'storycard:lastSeen:$userId';

  @override
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    super.dispose();
  }
}

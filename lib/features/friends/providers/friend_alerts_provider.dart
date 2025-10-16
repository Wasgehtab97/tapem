import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Lightweight provider that keeps track of pending friend requests and unread
/// friend chat messages without subscribing to the full collections. The
/// provider only listens to very small queries (limited to a single document)
/// so that a hot restart does not trigger thousands of document reads.
class FriendAlertsProvider extends ChangeNotifier {
  FriendAlertsProvider({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _pendingSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _unreadSub;

  bool _hasPendingRequests = false;
  bool _hasUnreadMessages = false;
  String? _uid;

  bool get hasPendingRequests => _hasPendingRequests;
  bool get hasUnreadMessages => _hasUnreadMessages;
  bool get showBadge => _hasPendingRequests || _hasUnreadMessages;

  /// Starts listening for pending requests and unread chats for [uid]. Calling
  /// this repeatedly with the same uid is ignored to avoid re-subscribing after
  /// a hot restart.
  void listen(String uid) {
    if (uid.isEmpty) {
      return;
    }
    if (_uid == uid && _pendingSub != null && _unreadSub != null) {
      return;
    }
    _uid = uid;
    _subscribe();
  }

  void _subscribe() {
    final uid = _uid;
    if (uid == null || uid.isEmpty) {
      return;
    }

    _pendingSub?.cancel();
    _pendingSub = _firestore
        .collection('friendRequests')
        .where('toUserId', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      final hasPending = snapshot.docs.isNotEmpty;
      if (hasPending != _hasPendingRequests) {
        _hasPendingRequests = hasPending;
        notifyListeners();
      }
    }, onError: (Object error, StackTrace stackTrace) {
      if (kDebugMode) {
        debugPrint('[FriendAlerts] pending listen error: $error');
      }
    });

    _unreadSub?.cancel();
    _unreadSub = _firestore
        .collection('users')
        .doc(uid)
        .collection('friendChats')
        .where('hasUnread', isEqualTo: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      final hasUnread = snapshot.docs.isNotEmpty;
      if (hasUnread != _hasUnreadMessages) {
        _hasUnreadMessages = hasUnread;
        notifyListeners();
      }
    }, onError: (Object error, StackTrace stackTrace) {
      if (kDebugMode) {
        debugPrint('[FriendAlerts] unread listen error: $error');
      }
    });
  }

  @override
  void dispose() {
    _pendingSub?.cancel();
    _unreadSub?.cancel();
    super.dispose();
  }
}

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/auth_providers.dart';
import '../../../core/providers/firebase_provider.dart';

class FriendAlertsState {
  const FriendAlertsState({
    this.hasPendingRequests = false,
    this.hasUnreadMessages = false,
    this.selfUid,
  });

  final bool hasPendingRequests;
  final bool hasUnreadMessages;
  final String? selfUid;

  bool get showBadge => hasPendingRequests || hasUnreadMessages;

  FriendAlertsState copyWith({
    bool? hasPendingRequests,
    bool? hasUnreadMessages,
    String? selfUid,
  }) {
    return FriendAlertsState(
      hasPendingRequests: hasPendingRequests ?? this.hasPendingRequests,
      hasUnreadMessages: hasUnreadMessages ?? this.hasUnreadMessages,
      selfUid: selfUid ?? this.selfUid,
    );
  }
}

class FriendAlertsNotifier extends Notifier<FriendAlertsState> {
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _pendingSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _unreadSub;
  late FirebaseFirestore _firestore;

  @override
  FriendAlertsState build() {
    _firestore = ref.watch(firebaseFirestoreProvider);
    ref.onDispose(() {
      _pendingSub?.cancel();
      _unreadSub?.cancel();
    });

    // Defer listening until after build completes
    Future.microtask(() {
      ref.listen<AuthViewState>(
        authViewStateProvider,
        (previous, next) {
          final uid = next.userId;
          final userChanged = previous?.userId != uid;
          final gymChanged = previous?.gymCode != next.gymCode;
          if (!next.isLoggedIn || uid == null || uid.isEmpty) {
            _pendingSub?.cancel();
            _unreadSub?.cancel();
            _pendingSub = null;
            _unreadSub = null;
            state = const FriendAlertsState();
            return;
          }
          if (userChanged || gymChanged || state.selfUid != uid) {
            _listen(uid);
          }
        },
        fireImmediately: true,
      );
    });

    return const FriendAlertsState();
  }

  void _listen(String uid) {
    if (uid.isEmpty) {
      return;
    }
    state = state.copyWith(selfUid: uid);
    _pendingSub?.cancel();
    _pendingSub = _firestore
        .collection('friendRequests')
        .where('toUserId', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      final hasPending = snapshot.docs.isNotEmpty;
      if (hasPending != state.hasPendingRequests) {
        state = state.copyWith(hasPendingRequests: hasPending);
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
      if (hasUnread != state.hasUnreadMessages) {
        state = state.copyWith(hasUnreadMessages: hasUnread);
      }
    }, onError: (Object error, StackTrace stackTrace) {
      if (kDebugMode) {
        debugPrint('[FriendAlerts] unread listen error: $error');
      }
    });
  }
}

final friendAlertsProvider =
    NotifierProvider<FriendAlertsNotifier, FriendAlertsState>(
  FriendAlertsNotifier.new,
);

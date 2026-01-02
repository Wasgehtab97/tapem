import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/firebase_provider.dart';

class FriendCalendarState {
  const FriendCalendarState({
    this.trainingDates = const [],
    this.gymIdsByDate = const <String, String>{},
    this.isLoading = false,
    this.error,
    this.activeFriendUid,
  });

  final List<String> trainingDates;
  final Map<String, String> gymIdsByDate;
  final bool isLoading;
  final String? error;
  final String? activeFriendUid;

  FriendCalendarState copyWith({
    List<String>? trainingDates,
    Map<String, String>? gymIdsByDate,
    bool? isLoading,
    String? error,
    bool clearError = false,
    String? activeFriendUid,
  }) {
    return FriendCalendarState(
      trainingDates: trainingDates ?? this.trainingDates,
      gymIdsByDate: gymIdsByDate ?? this.gymIdsByDate,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      activeFriendUid: activeFriendUid ?? this.activeFriendUid,
    );
  }
}

class FriendCalendarNotifier extends Notifier<FriendCalendarState> {
  late FirebaseFirestore _firestore;

  @override
  FriendCalendarState build() {
    _firestore = ref.watch(firebaseFirestoreProvider);
    return const FriendCalendarState();
  }

  Future<void> setActiveFriend(String uid) async {
    if (state.activeFriendUid == uid) {
      return;
    }
    state = state.copyWith(
      activeFriendUid: uid,
      trainingDates: const [],
      gymIdsByDate: const {},
      isLoading: true,
      clearError: true,
    );
    await _load();
  }

  Future<void> _load() async {
    final uid = state.activeFriendUid;
    if (uid == null || uid.isEmpty) {
      state = state.copyWith(
        trainingDates: const [],
        gymIdsByDate: const {},
        isLoading: false,
        clearError: true,
      );
      return;
    }

    try {
      final nowYear = DateTime.now().year;
      final start = DateTime(nowYear - 1, 1, 1);
      final end = DateTime(nowYear, 12, 31, 23, 59, 59, 999);
      print('[FriendCalendar] Loading training dates for friend=$uid range=${start.toIso8601String()}..${end.toIso8601String()}');
      final snap = await _firestore
          .collectionGroup('logs')
          .where('userId', isEqualTo: uid)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();
      print('[FriendCalendar] Found ${snap.docs.length} logs for friend=$uid');
      if (state.activeFriendUid != uid) {
        return;
      }
      final set = <String>{};
      final tempGymIds = <String, String>{};
      for (final doc in snap.docs) {
        final ts = doc.data()['timestamp'];
        if (ts is Timestamp) {
          final dt = ts.toDate();
          final key =
              '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
          final gymId = _extractGymId(doc.reference);
          if (gymId != null) {
            tempGymIds.putIfAbsent(key, () => gymId);
          }
          set.add(key);
        }
      }
      final dates = set.toList()..sort();
      final gymIds = {
        for (final key in dates)
          if (tempGymIds.containsKey(key)) key: tempGymIds[key]!,
      };
      print('[FriendCalendar] Processed ${dates.length} unique training days');
      state = state.copyWith(
        trainingDates: dates,
        gymIdsByDate: gymIds,
        isLoading: false,
        clearError: true,
      );
    } catch (e, st) {
      print('[FriendCalendar] ERROR loading calendar: $e');
      print(st);
      if (state.activeFriendUid == uid) {
        state = state.copyWith(
          isLoading: false,
          error: e.toString(),
        );
      }
    }
  }

  String? _extractGymId(DocumentReference<Map<String, dynamic>> ref) {
    final segments = ref.path.split('/');
    final index = segments.indexOf('gyms');
    if (index != -1 && index + 1 < segments.length) {
      return segments[index + 1];
    }
    return null;
  }
}

final friendCalendarProvider =
    NotifierProvider<FriendCalendarNotifier, FriendCalendarState>(
  FriendCalendarNotifier.new,
);

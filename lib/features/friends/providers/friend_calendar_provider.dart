import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FriendCalendarProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore;
  String? _activeFriendUid;
  List<String> _trainingDates = [];
  bool _isLoading = false;
  String? _error;

  FriendCalendarProvider({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  List<String> get trainingDates => List.unmodifiable(_trainingDates);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> setActiveFriend(String uid) async {
    if (_activeFriendUid == uid) return;
    _activeFriendUid = uid;
    await _load();
  }

  Future<void> _load() async {
    final uid = _activeFriendUid;
    if (uid == null) return;
    _isLoading = true;
    _error = null;
    _trainingDates = [];
    notifyListeners();
    try {
      final year = DateTime.now().year;
      final start = DateTime(year, 1, 1);
      final end = DateTime(year, 12, 31, 23, 59, 59, 999);
      QuerySnapshot<Map<String, dynamic>> snap;
      var usedSessions = true;
      try {
        final sessionsSnap = await _firestore
            .collectionGroup('sessions')
            .where('userId', isEqualTo: uid)
            .where('createdAt',
                isGreaterThanOrEqualTo: Timestamp.fromDate(start))
            .where(
              'createdAt',
              isLessThanOrEqualTo: Timestamp.fromDate(end),
            )
            .get();
        if (sessionsSnap.docs.isEmpty) {
          final legacyProbe = await _firestore
              .collectionGroup('logs')
              .where('userId', isEqualTo: uid)
              .limit(1)
              .get();
          if (legacyProbe.docs.isNotEmpty) {
            usedSessions = false;
            snap = await _firestore
                .collectionGroup('logs')
                .where('userId', isEqualTo: uid)
                .where(
                  'timestamp',
                  isGreaterThanOrEqualTo: Timestamp.fromDate(start),
                )
                .where(
                  'timestamp',
                  isLessThanOrEqualTo: Timestamp.fromDate(end),
                )
                .get();
          } else {
            snap = sessionsSnap;
          }
        } else {
          snap = sessionsSnap;
        }
      } on FirebaseException catch (e) {
        if (e.code == 'failed-precondition') {
          usedSessions = false;
          snap = await _firestore
              .collectionGroup('logs')
              .where('userId', isEqualTo: uid)
              .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
              .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(end))
              .get();
        } else {
          rethrow;
        }
      }
      if (_activeFriendUid != uid) return;
      final set = <String>{};
      for (final doc in snap.docs) {
        DateTime? dt;
        final data = doc.data();
        if (usedSessions) {
          final created = data['createdAt'];
          if (created is Timestamp) {
            dt = created.toDate();
          } else if (created is DateTime) {
            dt = created;
          }
        } else {
          final ts = data['timestamp'];
          if (ts is Timestamp) {
            dt = ts.toDate();
          }
        }
        if (dt == null) continue;
        final key =
            '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
        set.add(key);
      }
      _trainingDates = set.toList()..sort();
    } catch (e) {
      if (_activeFriendUid == uid) {
        _error = e.toString();
      }
    } finally {
      if (_activeFriendUid == uid) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }
}

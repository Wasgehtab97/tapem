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
      final snap = await _firestore
          .collectionGroup('logs')
          .where('userId', isEqualTo: uid)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();
      if (_activeFriendUid != uid) return;
      final set = <String>{};
      for (final doc in snap.docs) {
        final ts = doc.data()['timestamp'];
        if (ts is Timestamp) {
          final dt = ts.toDate();
          final key =
              '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
          set.add(key);
        }
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

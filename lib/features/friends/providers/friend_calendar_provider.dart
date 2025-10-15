import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Provides a lazily loaded view of a friend's workout activity.
///
/// The previous implementation queried the raw `logs` collection group for an
/// entire calendar year which resulted in thousands of reads for active users.
/// The provider now reads from aggregated day summaries written by a Cloud
/// Function (`logSummary/{userId}/days/{yyyy-mm-dd}`) and exposes explicit
/// paging and caching behaviour.
class FriendCalendarProvider extends ChangeNotifier {
  FriendCalendarProvider({
    FirebaseFirestore? firestore,
    Duration cacheTtl = const Duration(minutes: 5),
    int initialRangeDays = 30,
    int pageSize = 30,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _cacheTtl = cacheTtl,
        _initialRangeDays = initialRangeDays,
        _pageSize = pageSize;

  static const String _summaryRoot = 'logSummary';
  static const String _summaryCollection = 'days';

  final FirebaseFirestore _firestore;
  final Duration _cacheTtl;
  final int _initialRangeDays;
  final int _pageSize;

  String? _activeFriendUid;
  final SplayTreeSet<DateTime> _trainingDaySet =
      SplayTreeSet<DateTime>((a, b) => a.compareTo(b));
  bool _isLoading = false;
  bool _hasMore = true;
  bool _hasLoaded = false;
  String? _error;
  QueryDocumentSnapshot<Map<String, dynamic>>? _lastDocument;
  DateTime? _lastFetch;

  List<String> get trainingDates =>
      _trainingDaySet.map(_formatDate).toList(growable: false);
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  bool get hasLoaded => _hasLoaded;
  String? get error => _error;

  /// Sets the friend to inspect. Data is loaded lazily to avoid unnecessary
  /// Firestore reads when the UI is not visible yet.
  void setActiveFriend(String uid) {
    if (_activeFriendUid == uid) {
      return;
    }
    _activeFriendUid = uid;
    _resetState();
    notifyListeners();
  }

  /// Loads the default range (30 days by default) unless a fresh cache exists.
  Future<void> loadInitialRange({bool force = false}) async {
    final uid = _activeFriendUid;
    if (uid == null || uid.isEmpty) {
      return;
    }
    if (_isLoading) {
      return;
    }
    final lastFetch = _lastFetch;
    if (!force && _hasLoaded && lastFetch != null) {
      final delta = DateTime.now().difference(lastFetch);
      if (delta < _cacheTtl) {
        return;
      }
    }
    await _loadPage(limit: _initialRangeDays, reset: true);
  }

  /// Loads the next page of historic workout summaries on demand.
  Future<void> loadMore() async {
    if (!_hasMore || _isLoading) {
      return;
    }
    await _loadPage(limit: _pageSize, reset: false);
  }

  /// Forces a full reload from Firestore, bypassing the in-memory cache.
  Future<void> refresh() async {
    await _loadPage(limit: _initialRangeDays, reset: true, force: true);
  }

  void _resetState() {
    _trainingDaySet.clear();
    _isLoading = false;
    _hasMore = true;
    _hasLoaded = false;
    _error = null;
    _lastDocument = null;
    _lastFetch = null;
  }

  Future<void> _loadPage({
    required int limit,
    required bool reset,
    bool force = false,
  }) async {
    final uid = _activeFriendUid;
    if (uid == null || uid.isEmpty) {
      return;
    }

    if (_isLoading) {
      return;
    }

    if (!force && !reset && !_hasMore) {
      return;
    }

    _isLoading = true;
    if (reset) {
      _error = null;
    }
    notifyListeners();

    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection(_summaryRoot)
          .doc(uid)
          .collection(_summaryCollection)
          .orderBy(FieldPath.documentId, descending: true)
          .limit(limit);

      final cursor = _lastDocument;
      if (!reset && cursor != null) {
        query = query.startAfterDocument(cursor);
      }

      final snapshot = await query.get();
      if (_activeFriendUid != uid) {
        return;
      }

      if (reset) {
        _trainingDaySet.clear();
        _lastDocument = null;
      }

      for (final doc in snapshot.docs) {
        final parsed = _parseDate(doc.id);
        if (parsed != null) {
          _trainingDaySet.add(parsed);
        }
      }

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
      }

      _hasMore = snapshot.docs.length >= limit;
      _hasLoaded = true;
      _lastFetch = DateTime.now();
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

  static String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  DateTime? _parseDate(String raw) {
    try {
      final parts = raw.split('-');
      if (parts.length != 3) {
        return null;
      }
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);
      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }
}

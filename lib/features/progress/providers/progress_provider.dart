import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/core/providers/firebase_provider.dart';
import 'package:tapem/core/providers/gym_scoped_resettable.dart';
import 'package:tapem/features/progress/data/progress_backfill_service.dart';

class ProgressIndexItem {
  final String key;
  final String deviceId;
  final String? exerciseId;
  final bool isMulti;
  final String title;
  final String subtitle;
  final int sessionCount;

  const ProgressIndexItem({
    required this.key,
    required this.deviceId,
    required this.exerciseId,
    required this.isMulti,
    required this.title,
    required this.subtitle,
    required this.sessionCount,
  });
}

class ProgressPoint {
  final DateTime date;
  final double value;
  final String sessionId;

  const ProgressPoint({
    required this.date,
    required this.value,
    required this.sessionId,
  });
}

class ProgressMetaView {
  final String title;
  final String subtitle;
  final bool isMulti;

  const ProgressMetaView({
    required this.title,
    required this.subtitle,
    required this.isMulti,
  });
}

class ProgressProvider extends ChangeNotifier
    with GymScopedResettableChangeNotifier {
  final FirebaseFirestore _firestore;
  final ProgressBackfillService _backfillService;

  ProgressProvider({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _backfillService =
            ProgressBackfillService(firestore: firestore ?? FirebaseFirestore.instance);

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isBackfilling = false;
  String? _error;
  int _year = DateTime.now().year;
  final List<ProgressIndexItem> _items = [];
  final Map<String, List<ProgressPoint>> _pointsByKey = {};
  final Map<String, ProgressMetaView> _metaByKey = {};
  int _visibleCount = 0;

  static const int _pageSize = 6;

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isBackfilling => _isBackfilling;
  String? get error => _error;
  int get year => _year;
  List<ProgressIndexItem> get items => List.unmodifiable(_items);
  int get visibleCount => _visibleCount;

  bool get canLoadMore => _visibleCount < _items.length;

  List<ProgressIndexItem> get visibleItems {
    return _items.take(_visibleCount).toList(growable: false);
  }

  List<ProgressPoint> pointsFor(String key) {
    return _pointsByKey[key] ?? const [];
  }

  ProgressMetaView? metaFor(String key) {
    return _metaByKey[key];
  }

  Future<void> loadYear({
    required String gymId,
    required String userId,
    required int year,
  }) async {
    _isLoading = true;
    _error = null;
    _year = year;
    _items.clear();
    _pointsByKey.clear();
    _metaByKey.clear();
    _visibleCount = 0;
    notifyListeners();

    try {
      final indexRef = _firestore
          .collection('gyms')
          .doc(gymId)
          .collection('users')
          .doc(userId)
          .collection('progressIndex')
          .doc(year.toString());

      final snap = await indexRef.get();
      final data = snap.data();
      final rawItems = data?['items'] as Map<String, dynamic>? ?? {};

      final items = <ProgressIndexItem>[];
      rawItems.forEach((key, raw) {
        final map = raw as Map<String, dynamic>? ?? {};
        final sessionCount = (map['sessionCount'] as num?)?.toInt() ?? 0;
        if (sessionCount < 3) return;
        items.add(
          ProgressIndexItem(
            key: key,
            deviceId: map['deviceId'] as String? ?? '',
            exerciseId: map['exerciseId'] as String?,
            isMulti: map['isMulti'] == true,
            title: map['title'] as String? ?? key,
            subtitle: map['subtitle'] as String? ?? '',
            sessionCount: sessionCount,
          ),
        );
      });

      items.sort((a, b) => b.sessionCount.compareTo(a.sessionCount));
      _items.addAll(items);
      _visibleCount = _items.length < _pageSize ? _items.length : _pageSize;

      await _loadSummaries(
        gymId: gymId,
        userId: userId,
        items: _items.take(_visibleCount).toList(),
        year: year,
      );
    } catch (e, st) {
      _error = e.toString();
      debugPrint('❌ [ProgressProvider] loadYear error: $e');
      debugPrintStack(stackTrace: st);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore({
    required String gymId,
    required String userId,
  }) async {
    if (_isLoadingMore || !canLoadMore) return;
    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextCount =
          (_visibleCount + _pageSize).clamp(0, _items.length);
      final slice = _items.sublist(_visibleCount, nextCount);
      await _loadSummaries(
        gymId: gymId,
        userId: userId,
        items: slice,
        year: _year,
      );
      _visibleCount = nextCount;
    } catch (e, st) {
      _error = e.toString();
      debugPrint('❌ [ProgressProvider] loadMore error: $e');
      debugPrintStack(stackTrace: st);
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<ProgressBackfillResult?> backfillYear({
    required String gymId,
    required String userId,
    required int year,
  }) async {
    if (_isBackfilling) return null;
    _isBackfilling = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _backfillService.backfillYear(
        gymId: gymId,
        userId: userId,
        year: year,
      );
      await loadYear(gymId: gymId, userId: userId, year: year);
      return result;
    } catch (e, st) {
      _error = e.toString();
      debugPrint('❌ [ProgressProvider] backfill error: $e');
      debugPrintStack(stackTrace: st);
      return null;
    } finally {
      _isBackfilling = false;
      notifyListeners();
    }
  }

  Future<void> _loadSummaries({
    required String gymId,
    required String userId,
    required List<ProgressIndexItem> items,
    required int year,
  }) async {
    final futures = items.map((item) async {
      final docRef = _firestore
          .collection('gyms')
          .doc(gymId)
          .collection('users')
          .doc(userId)
          .collection('progress')
          .doc(item.key)
          .collection('years')
          .doc(year.toString());

      final snap = await docRef.get();
      final data = snap.data();
      final points = <ProgressPoint>[];
      final rawByDay = data?['pointsByDay'] as Map<String, dynamic>?;
      if (rawByDay != null && rawByDay.isNotEmpty) {
        rawByDay.forEach((_, raw) {
          if (raw is! Map<String, dynamic>) return;
          final ts = raw['ts'];
          final e1rm = raw['e1rm'];
          if (ts is! Timestamp || e1rm is! num) return;
          final sessionId = raw['sessionId'] as String? ?? '';
          points.add(
            ProgressPoint(
              date: ts.toDate(),
              value: e1rm.toDouble(),
              sessionId: sessionId,
            ),
          );
        });
      } else {
        final rawPoints = data?['points'] as List<dynamic>? ?? [];
        for (final raw in rawPoints) {
          if (raw is! Map<String, dynamic>) continue;
          final ts = raw['ts'];
          final e1rm = raw['e1rm'];
          if (ts is! Timestamp || e1rm is! num) continue;
          final sessionId = raw['sessionId'] as String? ?? '';
          points.add(
            ProgressPoint(
              date: ts.toDate(),
              value: e1rm.toDouble(),
              sessionId: sessionId,
            ),
          );
        }
      }
      points.sort((a, b) => a.date.compareTo(b.date));
      _pointsByKey[item.key] = points;

      final title = (data?['title'] as String?)?.trim() ?? '';
      final subtitle = (data?['subtitle'] as String?)?.trim() ?? '';
      final isMulti = data?['isMulti'] == true;
      if (title.isNotEmpty || subtitle.isNotEmpty) {
        _metaByKey[item.key] = ProgressMetaView(
          title: title,
          subtitle: subtitle,
          isMulti: isMulti,
        );
      }
    }).toList();

    await Future.wait(futures);
  }

  @override
  void resetGymScopedState() {
    _isLoading = false;
    _isLoadingMore = false;
    _isBackfilling = false;
    _error = null;
    _items.clear();
    _pointsByKey.clear();
    _metaByKey.clear();
    _visibleCount = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    disposeGymScopedRegistration();
    super.dispose();
  }
}

final progressProvider = ChangeNotifierProvider<ProgressProvider>((ref) {
  final provider = ProgressProvider(
    firestore: ref.watch(firebaseFirestoreProvider),
  );
  final gymScopedController = ref.watch(gymScopedStateControllerProvider);
  provider.registerGymScopedResettable(gymScopedController);

  ref.listen<AuthViewState>(
    authViewStateProvider,
    (previous, next) {
      final gymChanged = previous?.gymCode != next.gymCode;
      final userChanged = previous?.userId != next.userId;
      if (!gymChanged && !userChanged) {
        if (!next.isLoggedIn || next.gymCode == null || next.userId == null) {
          provider.resetGymScopedState();
        }
        return;
      }
      provider.resetGymScopedState();
    },
    fireImmediately: true,
  );

  ref.onDispose(provider.dispose);
  return provider;
});

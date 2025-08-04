import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'models/feedback_entry.dart';

typedef LogFn = void Function(String message, [StackTrace? stack]);

// TODO: replace with real logging service
void _defaultLog(String message, [StackTrace? stack]) {
  if (stack != null) {
    debugPrintStack(label: message, stackTrace: stack);
  } else {
    debugPrint(message);
  }
}

class FeedbackProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore;
  final LogFn _log;

  FeedbackProvider({required FirebaseFirestore firestore, LogFn? log})
    : _firestore = firestore,
      _log = log ?? _defaultLog;

  bool _loading = false;
  String? _error;
  final List<FeedbackEntry> _entries = [];

  bool get isLoading => _loading;
  String? get error => _error;
  List<FeedbackEntry> get entries => List.unmodifiable(_entries);

  List<FeedbackEntry> get openEntries =>
      _entries.where((e) => !e.isDone).toList();
  List<FeedbackEntry> get doneEntries =>
      _entries.where((e) => e.isDone).toList();

  Future<void> loadFeedback(String gymId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final snap =
          await _firestore
              .collection('gyms')
              .doc(gymId)
              .collection('feedback')
              .orderBy('createdAt', descending: true)
              .get();
      _entries
        ..clear()
        ..addAll(
          snap.docs.map((d) => FeedbackEntry.fromMap(d.id, d.data(), gymId)),
        );
    } catch (e, st) {
      _log('FeedbackProvider.loadFeedback error: $e', st);
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> submitFeedback({
    required String gymId,
    required String deviceId,
    required String userId,
    required String text,
  }) async {
    try {
      final data = {
        'deviceId': deviceId,
        'userId': userId,
        'text': text,
        'createdAt': Timestamp.now(),
        'isDone': false,
      };
      await _firestore
          .collection('gyms')
          .doc(gymId)
          .collection('feedback')
          .add(data);
    } catch (e, st) {
      _log('FeedbackProvider.submitFeedback error: $e', st);
      _error = e.toString();
    }
  }

  Future<void> markDone({
    required String gymId,
    required String entryId,
  }) async {
    try {
      await _firestore
          .collection('gyms')
          .doc(gymId)
          .collection('feedback')
          .doc(entryId)
          .update({'isDone': true});
      final idx = _entries.indexWhere((e) => e.id == entryId);
      if (idx != -1) {
        _entries[idx] = FeedbackEntry(
          id: _entries[idx].id,
          gymId: gymId,
          deviceId: _entries[idx].deviceId,
          userId: _entries[idx].userId,
          text: _entries[idx].text,
          createdAt: _entries[idx].createdAt,
          isDone: true,
        );
        notifyListeners();
      }
    } catch (e, st) {
      _log('FeedbackProvider.markDone error: $e', st);
      _error = e.toString();
    }
  }
}

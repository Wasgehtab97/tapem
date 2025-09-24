import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsProvider({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  bool? _creatineEnabled;
  bool? _showPreviousSets;
  bool _isLoading = false;
  String? _error;
  String? _uid;

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get creatineEnabled => _creatineEnabled ?? false;
  bool get showPreviousSets => _showPreviousSets ?? false;

  DocumentReference<Map<String, dynamic>> _doc(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('settings');
  }

  Future<void> load(String uid) async {
    if (_uid == uid && _creatineEnabled != null && _showPreviousSets != null) {
      return;
    }
    _uid = uid;
    _isLoading = true;
    _error = null;
    _showPreviousSets = null;
    notifyListeners();
    try {
      final ref = _doc(uid);
      final snap = await ref.get();
      final data = snap.data();
      final updates = <String, dynamic>{};

      final creatine = data?['creatineEnabled'];
      if (creatine is bool) {
        _creatineEnabled = creatine;
      } else {
        _creatineEnabled = false;
        updates['creatineEnabled'] = false;
      }

      final showPrev = data?['showPreviousSets'];
      if (showPrev is bool) {
        _showPreviousSets = showPrev;
      } else {
        _showPreviousSets = false;
        updates['showPreviousSets'] = false;
      }

      if (updates.isNotEmpty) {
        await ref.set(updates, SetOptions(merge: true));
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setCreatineEnabled(bool value) async {
    final uid = _uid;
    if (uid == null) return;
    final old = _creatineEnabled;
    _creatineEnabled = value;
    notifyListeners();
    try {
      await _doc(uid).set({'creatineEnabled': value}, SetOptions(merge: true));
    } catch (e) {
      _creatineEnabled = old;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> setShowPreviousSets(bool value) async {
    final uid = _uid;
    if (uid == null) return;
    final old = _showPreviousSets;
    _showPreviousSets = value;
    notifyListeners();
    try {
      await _doc(uid).set({'showPreviousSets': value}, SetOptions(merge: true));
    } catch (e) {
      _showPreviousSets = old;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}

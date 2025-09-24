import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsProvider({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  bool? _creatineEnabled;
  bool _showPreviousSets = false;
  bool _isLoading = false;
  String? _error;
  String? _uid;

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get creatineEnabled => _creatineEnabled ?? false;
  bool get showPreviousSets => _showPreviousSets;

  DocumentReference<Map<String, dynamic>> _doc(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('settings');
  }

  Future<void> load(String uid) async {
    if (_uid == uid && _creatineEnabled != null) return;
    _uid = uid;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final ref = _doc(uid);
      final snap = await ref.get();
      final data = snap.data();
      if (data != null) {
        final merged = <String, dynamic>{};
        if (data['creatineEnabled'] != null) {
          _creatineEnabled = data['creatineEnabled'] as bool;
        } else {
          _creatineEnabled = false;
          merged['creatineEnabled'] = false;
        }
        if (data['showPreviousSets'] != null) {
          _showPreviousSets = data['showPreviousSets'] as bool;
        } else {
          _showPreviousSets = false;
          merged['showPreviousSets'] = false;
        }
        if (merged.isNotEmpty) {
          await ref.set(merged, SetOptions(merge: true));
        }
      } else {
        _creatineEnabled = false;
        _showPreviousSets = false;
        await ref.set({
          'creatineEnabled': false,
          'showPreviousSets': false,
        }, SetOptions(merge: true));
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

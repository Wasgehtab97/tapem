import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsProvider({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  bool? _creatineEnabled;
  bool? _showLastSessionInSetCard;
  bool _isLoading = false;
  String? _error;
  String? _uid;

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get creatineEnabled => _creatineEnabled ?? false;
  bool get showLastSessionInSetCard => _showLastSessionInSetCard ?? true;

  DocumentReference<Map<String, dynamic>> _doc(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('settings');
  }

  Future<void> load(String uid) async {
    if (_uid == uid &&
        _creatineEnabled != null &&
        _showLastSessionInSetCard != null) {
      return;
    }
    _uid = uid;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final ref = _doc(uid);
      final snap = await ref.get();
      final data = snap.data();
      final updates = <String, dynamic>{};
      if (data != null && data['creatineEnabled'] != null) {
        _creatineEnabled = data['creatineEnabled'] as bool;
      } else {
        _creatineEnabled = false;
        updates['creatineEnabled'] = false;
      }
      if (data != null && data['showLastSessionInSetCard'] != null) {
        _showLastSessionInSetCard =
            data['showLastSessionInSetCard'] as bool;
      } else {
        _showLastSessionInSetCard = true;
        updates['showLastSessionInSetCard'] = true;
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

  Future<void> setShowLastSessionInSetCard(bool value) async {
    final uid = _uid;
    if (uid == null) return;
    final old = _showLastSessionInSetCard;
    _showLastSessionInSetCard = value;
    notifyListeners();
    try {
      await _doc(uid)
          .set({'showLastSessionInSetCard': value}, SetOptions(merge: true));
    } catch (e) {
      _showLastSessionInSetCard = old;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}

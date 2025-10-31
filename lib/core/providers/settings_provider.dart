import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsProvider({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  bool? _creatineEnabled;
  bool _isLoading = false;
  String? _error;
  String? _uid;
  String? _gender;
  double? _bodyWeightKg;

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get creatineEnabled => _creatineEnabled ?? false;
  String? get gender => _gender;
  double? get bodyWeightKg => _bodyWeightKg;

  DocumentReference<Map<String, dynamic>> _doc(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('settings');
  }

  Future<void> load(String uid) async {
    if (_uid == uid && _creatineEnabled != null) {
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
      _gender = data != null ? data['gender'] as String? : null;
      final bw = data != null ? data['bodyWeightKg'] : null;
      _bodyWeightKg = bw is num ? bw.toDouble() : null;
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

  Future<void> setGender(String? value) async {
    final uid = _uid;
    if (uid == null) return;
    final old = _gender;
    _gender = value;
    notifyListeners();
    try {
      await _doc(uid).set(
        value == null || value.isEmpty
            ? {'gender': FieldValue.delete()}
            : {'gender': value},
        SetOptions(merge: true),
      );
    } catch (e) {
      _gender = old;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> setBodyWeightKg(double? value) async {
    final uid = _uid;
    if (uid == null) return;
    final old = _bodyWeightKg;
    _bodyWeightKg = value;
    notifyListeners();
    try {
      await _doc(uid).set(
        value == null
            ? {'bodyWeightKg': FieldValue.delete()}
            : {'bodyWeightKg': value},
        SetOptions(merge: true),
      );
    } catch (e) {
      _bodyWeightKg = old;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

}

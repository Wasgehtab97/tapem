import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../theme/brand_theme_preset.dart';

class ThemePreferenceProvider extends ChangeNotifier {
  ThemePreferenceProvider({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  String? _uid;
  bool _isLoading = false;
  String? _error;
  BrandThemeId? _override;
  bool _hasLoaded = false;

  bool get isLoading => _isLoading;
  String? get error => _error;
  BrandThemeId? get override => _override;
  bool get hasLoaded => _hasLoaded;

  DocumentReference<Map<String, dynamic>> _doc(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('theme');
  }

  void setUser(String? uid) {
    if (uid == null) {
      _uid = null;
      _override = null;
      _hasLoaded = false;
      notifyListeners();
      return;
    }
    if (_uid == uid && _hasLoaded) {
      return;
    }
    _uid = uid;
    _load();
  }

  Future<void> _load() async {
    final uid = _uid;
    if (uid == null) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final snap = await _doc(uid).get();
      final data = snap.data();
      final value = data != null ? data['themeId'] as String? : null;
      _override = value != null ? BrandThemeIdX.fromStorage(value) : null;
      _hasLoaded = true;
    } catch (e) {
      _error = e.toString();
      _override = null;
      _hasLoaded = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setTheme(BrandThemeId? theme) async {
    final uid = _uid;
    if (uid == null) {
      return;
    }
    final previous = _override;
    _override = theme;
    notifyListeners();
    try {
      final ref = _doc(uid);
      if (theme == null) {
        await ref.set({'themeId': FieldValue.delete()}, SetOptions(merge: true));
      } else {
        await ref.set({'themeId': theme.storageValue}, SetOptions(merge: true));
      }
    } catch (e) {
      _override = previous;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  BrandThemeId? manualDefaultForGym(String? gymId) {
    if (gymId == 'lifthouse_koblenz') {
      return BrandThemeId.magentaViolet;
    }
    if (gymId == 'Club Aktiv' || gymId == 'FitnessFirst MyZeil') {
      return null;
    }
    return BrandThemeId.mintTurquoise;
  }

  List<BrandThemeId> availableForGym(String? gymId) {
    final defaultTheme = manualDefaultForGym(gymId);
    final base = BrandThemeId.values.toList();
    if (defaultTheme == null) {
      return base;
    }
    final others = base.where((e) => e != defaultTheme).toList();
    return [defaultTheme, ...others];
  }
}

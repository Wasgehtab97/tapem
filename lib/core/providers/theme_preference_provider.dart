import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/brand_theme_preset.dart';

class ThemePreferenceProvider extends ChangeNotifier {
  ThemePreferenceProvider({
    FirebaseFirestore? firestore,
    SharedPreferences? preferences,
    Future<Map<String, dynamic>?> Function(String uid)? fetchOverride,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _preferences = preferences,
        _fetchOverride = fetchOverride;

  final FirebaseFirestore _firestore;
  SharedPreferences? _preferences;
  final Future<Map<String, dynamic>?> Function(String uid)? _fetchOverride;

  String? _uid;
  bool _isLoading = false;
  String? _error;
  BrandThemeId? _override;
  bool _hasLoaded = false;

  bool get isLoading => _isLoading;
  String? get error => _error;
  BrandThemeId? get override => _override;
  bool get hasLoaded => _hasLoaded;

  static const _prefsKeyPrefix = 'theme_override_';

  Future<SharedPreferences> _prefs() async {
    final existing = _preferences;
    if (existing != null) {
      return existing;
    }
    final prefs = await SharedPreferences.getInstance();
    _preferences = prefs;
    return prefs;
  }

  String _prefsKey(String uid) => '$_prefsKeyPrefix$uid';

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
    if (_uid != uid) {
      _override = null;
      _hasLoaded = false;
    }
    _uid = uid;
    _load();
  }

  Future<void> _load() async {
    final uid = _uid;
    if (uid == null) return;
    _isLoading = true;
    _error = null;

    await _loadCachedOverride(uid);
    notifyListeners();
    try {
      final fetchOverride = _fetchOverride;
      final data = fetchOverride != null
          ? await fetchOverride(uid)
          : (await _doc(uid).get()).data();
      final value = data != null ? data['themeId'] as String? : null;
      final resolved = value != null ? BrandThemeIdX.fromStorage(value) : null;
      _override = resolved;
      _hasLoaded = true;
      await _persistOverride(uid, resolved);
    } catch (e) {
      _error = e.toString();
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
        await _persistOverride(uid, null);
      } else {
        await ref.set({'themeId': theme.storageValue}, SetOptions(merge: true));
        await _persistOverride(uid, theme);
      }
    } catch (e) {
      _override = previous;
      _error = e.toString();
      await _persistOverride(uid, previous);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _loadCachedOverride(String uid) async {
    final prefs = await _prefs();
    final cached = prefs.getString(_prefsKey(uid));
    final cachedId = cached != null ? BrandThemeIdX.fromStorage(cached) : null;
    if (cachedId != null && cachedId != _override) {
      _override = cachedId;
    }
  }

  Future<void> _persistOverride(String uid, BrandThemeId? theme) async {
    final prefs = await _prefs();
    if (theme == null) {
      await prefs.remove(_prefsKey(uid));
    } else {
      await prefs.setString(_prefsKey(uid), theme.storageValue);
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

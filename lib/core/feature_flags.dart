import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// Runtime feature flags loaded from remote config or environment.
class FeatureFlags extends ChangeNotifier {
  FeatureFlags._();

  static final FeatureFlags instance = FeatureFlags._();

  bool _uiSetsTableV1 = false;

  bool get uiSetsTableV1 => _uiSetsTableV1;

  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  /// Loads feature flags from remote config and environment overrides.
  Future<void> load() async {
    bool value = false;
    try {
      await _remoteConfig.fetchAndActivate();
      value = _remoteConfig.getBool('ui_sets_table_v1');
    } catch (_) {
      // Ignore, fallback below.
    }

    // Debug override via --dart-define=UI_SETS_TABLE_V1=true
    const env = String.fromEnvironment('UI_SETS_TABLE_V1');
    if (env.isNotEmpty) {
      value = env.toLowerCase() == 'true';
    }
    _setUiSetsTableV1(value);

    // Listen for future remote config updates.
    _remoteConfig.onConfigUpdated.listen((event) async {
      await _remoteConfig.activate();
      _setUiSetsTableV1(_remoteConfig.getBool('ui_sets_table_v1'));
    });
  }

  void _setUiSetsTableV1(bool value) {
    if (_uiSetsTableV1 != value) {
      _uiSetsTableV1 = value;
      notifyListeners();
    }
  }
}

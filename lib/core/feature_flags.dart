import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// Runtime feature flags backed by Firebase Remote Config.
class FeatureFlags extends ChangeNotifier {
  FeatureFlags._(this._rc);

  final FirebaseRemoteConfig _rc;

  bool _uiSetsTableV1 = false;
  bool get uiSetsTableV1 => _uiSetsTableV1;

  /// Bootstrap the feature flags service.
  static Future<FeatureFlags> init(FirebaseRemoteConfig rc) async {
    final flags = FeatureFlags._(rc);
    await flags._bootstrap();
    return flags;
  }

  Future<void> _bootstrap() async {
    await _rcSafe(() async {
      await _rc.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval:
            kDebugMode ? Duration.zero : const Duration(minutes: 30),
      ));
      await _rc.setDefaults(const {
        'ui_sets_table_v1': false,
      });
      await _rc.fetchAndActivate();
    });

    _updateFromRemoteConfig();

    _rc.onConfigUpdated.listen((_) async {
      await _rcSafe(() async {
        await _rc.activate();
        _updateFromRemoteConfig();
      });
    });
  }

  Future<void> _rcSafe(Future<void> Function() cb) async {
    try {
      await cb();
    } catch (e, s) {
      FlutterError.reportError(
        FlutterErrorDetails(exception: e, stack: s),
      );
    }
  }

  void _updateFromRemoteConfig() {
    bool value = false;
    String source = 'default';

    try {
      value = _rc.getBool('ui_sets_table_v1');
      source = 'rc';
    } catch (e, s) {
      FlutterError.reportError(
        FlutterErrorDetails(exception: e, stack: s),
      );
    }

    const env = String.fromEnvironment('UI_SETS_TABLE_V1');
    if (env.isNotEmpty) {
      value = env.toLowerCase() == 'true';
      source = 'define';
    }

    if (kDebugMode) {
      debugPrint('FeatureFlags.uiSetsTableV1 from $source => $value');
    }

    if (_uiSetsTableV1 != value) {
      _uiSetsTableV1 = value;
      notifyListeners();
    }
  }
}


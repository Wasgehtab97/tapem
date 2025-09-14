import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

class RC {
  RC._();

  static FirebaseRemoteConfig get _rc => FirebaseRemoteConfig.instance;

  static Future<void> init() async {
    await _rc.setDefaults(<String, dynamic>{
      'avatars_v2_enabled': false,
      'avatars_v2_migration_on': false,
      'avatars_v2_images_cdn': false,
      'avatars_v2_grants_enabled': false,
      'cardio_max_speed_kmh': 40.0,
      'cardio_max_duration_sec': 10800,
    });
    await _rc.fetchAndActivate();
  }

  static bool get avatarsV2Enabled => _rc.getBool('avatars_v2_enabled');
  static bool get avatarsV2MigrationOn =>
      _rc.getBool('avatars_v2_migration_on');
  static bool get avatarsV2ImagesCdn =>
      _rc.getBool('avatars_v2_images_cdn');
  static bool get avatarsV2GrantsEnabled =>
      _rc.getBool('avatars_v2_grants_enabled');

  @visibleForTesting
  static double cardioMaxSpeedFrom(double rcVal) => rcVal > 0 ? rcVal : 40.0;

  static double get cardioMaxSpeedKmH {
    try {
      final v = _rc.getDouble('cardio_max_speed_kmh');
      return cardioMaxSpeedFrom(v);
    } catch (_) {
      return 40.0;
    }
  }

  static int get cardioMaxDurationSec {
    try {
      return _rc.getInt('cardio_max_duration_sec');
    } catch (_) {
      return 10800;
    }
  }
}

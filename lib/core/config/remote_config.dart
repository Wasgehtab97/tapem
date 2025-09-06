import 'package:firebase_remote_config/firebase_remote_config.dart';

class RC {
  RC._();

  static final FirebaseRemoteConfig _rc = FirebaseRemoteConfig.instance;

  static Future<void> init() async {
    await _rc.setDefaults(<String, dynamic>{
      'avatars_v2_enabled': false,
      'avatars_v2_migration_on': false,
      'avatars_v2_images_cdn': false,
      'avatars_v2_grants_enabled': false,
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
}

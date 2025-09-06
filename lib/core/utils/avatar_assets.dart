class AvatarAssets {
  AvatarAssets._();

  static const defaultKey = 'default';
  static const keys = [defaultKey, 'default2'];

  static String path(String key) {
    final resolved = keys.contains(key) ? key : defaultKey;
    return 'assets/avatars/' + resolved + '.png';
  }
}

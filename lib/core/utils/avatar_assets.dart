/// Avatar key constants and helpers used throughout the app.
class AvatarKeys {
  AvatarKeys._();

  static const globalDefault = 'global/default';
  static const globalDefault2 = 'global/default2';
}

/// Constants and helpers for avatar assets.
class AvatarAssets {
  AvatarAssets._();

  static const manifestPrefix = 'assets/avatars/';
  static const placeholderPath = 'assets/logos/logo.png';

  /// Normalises [input] to the `<namespace>/<name>` format.
  ///
  /// Legacy inputs such as `default` or `default2` are mapped to the
  /// respective `global/` variants. Unqualified names prefer [currentGymId]
  /// when provided; otherwise the global namespace is used.
  static String normalizeAvatarKey(
    String input, {
    String? currentGymId,
  }) {
    if (input.contains('/')) return input;
    if (input == 'default') return AvatarKeys.globalDefault;
    if (input == 'default2') return AvatarKeys.globalDefault2;
    final ns = currentGymId ?? 'global';
    return '$ns/$input';
  }
}


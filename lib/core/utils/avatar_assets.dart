import 'package:path/path.dart' as p;

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
  static final RegExp _slugPattern = RegExp(r'^[a-z0-9_]+$');

  static bool isGlobalNamespace(String ns) => ns == 'global';
  static bool isGymNamespace(String ns) =>
      ns != 'global' && _slugPattern.hasMatch(ns);

  /// Normalises [input] to the `<namespace>/<name>` format.
  ///
  /// Inputs may already be in `<namespace>/<name>` or full asset paths like
  /// `assets/avatars/<namespace>/<name>.png`. Optional `.png` suffixes are
  /// removed. Legacy names like `default`/`default2` are mapped to the
  /// respective global keys. Unqualified names prefer [currentGymId] when
  /// provided; otherwise the global namespace is used.
  static String normalizeKey(
    String input, {
    String? currentGymId,
  }) {
    var key = input.trim();
    if (key.isEmpty) return AvatarKeys.globalDefault;

    if (key.startsWith(manifestPrefix)) {
      key = key.substring(manifestPrefix.length);
    }

    key = key.replaceAll('\\', '/');

    if (!key.contains('/')) {
      if (key == 'default') return AvatarKeys.globalDefault;
      if (key == 'default2') return AvatarKeys.globalDefault2;
      final ns = currentGymId ?? 'global';
      return '$ns/${p.basenameWithoutExtension(key)}';
    }

    final parts = key.split('/');
    final ns = parts.first;
    final name = p.basenameWithoutExtension(parts.last);
    return '$ns/$name';
  }

  @Deprecated('Use normalizeKey')
  static String normalizeAvatarKey(
    String input, {
    String? currentGymId,
  }) =>
      normalizeKey(input, currentGymId: currentGymId);
}


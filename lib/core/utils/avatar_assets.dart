import 'package:flutter/foundation.dart';
import 'package:tapem/features/avatars/domain/services/avatar_catalog.dart';

/// Avatar key constants and helpers used throughout the app.
class AvatarKeys {
  AvatarKeys._();

  static const globalDefault = 'global/default';
  static const globalDefault2 = 'global/default2';
}

/// Utilities for working with avatar keys.
class AvatarAssets {
  AvatarAssets._();

  static final Set<String> _warned = <String>{};

  /// Normalises [input] to the `<namespace>/<name>` format.
  ///
  /// Legacy inputs such as `default` or `default2` are mapped to
  /// `global/default` and `global/default2` respectively. Unqualified names
  /// will prefer the [currentGymId] namespace when available in the
  /// [AvatarCatalog]; otherwise the global namespace is used. Unknown names
  /// fall back to [AvatarKeys.globalDefault] with a single debug warning.
  static String normalizeAvatarKey(
    String input, {
    String? currentGymId,
    bool preferGymNamespaceForNonDefaults = true,
  }) {
    if (input.contains('/')) return input;
    if (input == 'default') return AvatarKeys.globalDefault;
    if (input == 'default2') return AvatarKeys.globalDefault2;

    final catalog = AvatarCatalog.instance;

    if (currentGymId != null && preferGymNamespaceForNonDefaults) {
      final gymKey = '$currentGymId/$input';
      if (catalog.hasKey(gymKey)) return gymKey;
    }

    final globalKey = 'global/$input';
    if (catalog.hasKey(globalKey)) return globalKey;

    if (kDebugMode && !_warned.contains(input)) {
      debugPrint('[Avatar] unknown key "$input" – using global/default');
      _warned.add(input);
    }
    return AvatarKeys.globalDefault;
  }
}


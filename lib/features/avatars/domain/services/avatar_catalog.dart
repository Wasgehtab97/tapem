import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:tapem/core/utils/avatar_assets.dart';

/// Catalog of avatar assets discovered at runtime from the [AssetManifest].
///
/// Keys use the form `<namespace>/<name>` where `namespace` is either `global`
/// or the gym id. Paths returned are full asset paths such as
/// `assets/avatars/global/default.png`.
class AvatarCatalog {
  AvatarCatalog._();

  static final AvatarCatalog instance = AvatarCatalog._();

  final Map<String, String> _paths = <String, String>{};
  final Set<String> _global = <String>{};
  final Map<String, Set<String>> _gym = <String, Set<String>>{};
  final Set<String> _manifestPaths = <String>{};

  bool manifestHasPrefix = false;
  bool manifestHasGlobalDefault = false;
  bool _warmed = false;

  bool get warmed => _warmed;
  Set<String> get manifestPaths => _manifestPaths;

  Future<void> warmUp({AssetBundle? bundle}) async {
    if (_warmed) return;
    final AssetBundle b = bundle ?? rootBundle;
    String manifestStr;
    try {
      manifestStr = await b.loadString('AssetManifest.json');
    } catch (_) {
      manifestStr = await b.loadString('AssetManifest.bin.json');
    }
    final Map<String, dynamic> manifest =
        json.decode(manifestStr) as Map<String, dynamic>;
    const prefix = AvatarAssets.manifestPrefix;
    _paths.clear();
    _global.clear();
    _gym.clear();
    _manifestPaths.clear();
    manifestHasPrefix = false;
    manifestHasGlobalDefault = false;

    for (final path in manifest.keys) {
      if (!path.startsWith(prefix) ||
          !path.toLowerCase().endsWith('.png')) {
        continue;
      }
      manifestHasPrefix = true;
      _manifestPaths.add(path);
      final rel = path.substring(prefix.length);
      final slash = rel.indexOf('/');
      if (slash == -1) continue;
      final namespace = rel.substring(0, slash);
      final file = rel.substring(slash + 1);
      final name = p.basenameWithoutExtension(file);
      if (AvatarAssets.isGlobalNamespace(namespace)) {
        final key = '$namespace/$name';
        _paths[key] = path;
        _global.add(key);
      } else if (AvatarAssets.isGymNamespace(namespace)) {
        final key = '$namespace/$name';
        _paths[key] = path;
        (_gym[namespace] ??= <String>{}).add(key);
      }
    }
    manifestHasGlobalDefault = _paths.containsKey(AvatarKeys.globalDefault);
    if (kDebugMode) {
      if (!manifestHasPrefix) {
        debugPrint(
            '[AvatarCatalog] manifest_missing_prefix assets/avatars/ – check pubspec.yaml and physical paths.');
      }
      if (!manifestHasGlobalDefault) {
        debugPrint(
            '[AvatarCatalog] manifest_missing: assets/avatars/global/default.png');
      }
      final gymsLog =
          _gym.entries.map((e) => '${e.key}:${e.value.length}').join(', ');
      debugPrint(
          '[AvatarCatalog] warmup: global=${_global.length}, gyms={$gymsLog}');
    }
    _warmed = true;
  }

  final Set<String> _warnedMissing = <String>{};
  bool _warnedMissingGlobalDefault = false;

  /// Resolves [key] to a manifest path or falls back to default/placeholder.
  String resolvePathOrFallback(String key, {String? gymId}) {
    if (!_warmed) unawaited(warmUp());
    final normalized = AvatarAssets.normalizeKey(key, currentGymId: gymId);
    final path = _paths[normalized];
    if (path != null) return path;
    if (kDebugMode && _warnedMissing.add(normalized)) {
      debugPrint('[AvatarCatalog] missing key $normalized');
    }
    final ns = normalized.split('/').first;
    if (!AvatarAssets.isGlobalNamespace(ns) && manifestHasGlobalDefault) {
      return _paths[AvatarKeys.globalDefault]!;
    }
    if (!manifestHasGlobalDefault && kDebugMode && !_warnedMissingGlobalDefault) {
      debugPrint('[AvatarCatalog] missing global default');
      _warnedMissingGlobalDefault = true;
    }
    return AvatarAssets.placeholderPath;
  }

  Set<String> availableGlobalKeys() {
    if (!_warmed) unawaited(warmUp());
    return _global.toSet();
  }

  Set<String> availableGymKeys(String gymId) {
    if (!_warmed) unawaited(warmUp());
    return (_gym[gymId] ?? const <String>{}).toSet();
  }

  /// Returns available keys excluding [owned] for the given [gymId].
  ({List<String> global, List<String> gym}) availableKeys({
    required Set<String> owned,
    required String gymId,
  }) {
    final g =
        availableGlobalKeys().where((k) => !owned.contains(k)).toList()..sort();
    final gg =
        availableGymKeys(gymId).where((k) => !owned.contains(k)).toList()..sort();
    return (global: g, gym: gg);
  }

  int get globalCount => _global.length;
  int gymCount(String gymId) => _gym[gymId]?.length ?? 0;

  void resetForTests() {
    _paths.clear();
    _global.clear();
    _gym.clear();
    _manifestPaths.clear();
    _warnedMissing.clear();
    manifestHasPrefix = false;
    manifestHasGlobalDefault = false;
    _warmed = false;
  }
}

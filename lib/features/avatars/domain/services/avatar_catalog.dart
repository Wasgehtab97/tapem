import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Catalog of avatar assets discovered at runtime from the [AssetManifest].
///
/// Keys are relative paths without the `assets/avatars/` prefix and without the
/// `.png` extension, e.g. `global/default` or `gym_01/kurzhantel`.
class AvatarCatalog {
  AvatarCatalog._internal();

  static final AvatarCatalog instance = AvatarCatalog._internal();

  bool _loaded = false;
  bool _loading = false;

  final List<String> _global = <String>['global/default', 'global/default2'];
  final Map<String, List<String>> _byGym = <String, List<String>>{};
  final Set<String> _allKeys = <String>{'global/default', 'global/default2'};

  Future<void> load() async {
    if (_loaded || _loading) return;
    _loading = true;
    try {
      final manifest =
          await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> data =
          json.decode(manifest) as Map<String, dynamic>;
      const prefix = 'assets/avatars/';
      const ext = '.png';
      for (final path in data.keys) {
        if (path.startsWith(prefix) && path.endsWith(ext)) {
          final key = path.substring(prefix.length, path.length - ext.length);
          if (_allKeys.contains(key)) continue;
          _allKeys.add(key);
          if (key.startsWith('global/')) {
            _global.add(key);
          } else {
            final slash = key.indexOf('/');
            if (slash != -1) {
              final gymId = key.substring(0, slash);
              (_byGym[gymId] ??= <String>[]).add(key);
            }
          }
        }
      }
      // sort for stable order
      _global.sort();
      for (final list in _byGym.values) {
        list.sort();
      }
    } finally {
      _loaded = true;
      _loading = false;
    }
  }

  /// Returns all global avatar keys.
  List<String> listGlobal() {
    if (!_loaded) {
      // fire and forget load
      unawaited(load());
    }
    return List<String>.from(_global);
  }

  /// Returns all avatar keys for a given gym.
  List<String> listForGym(String gymId) {
    if (!_loaded) {
      unawaited(load());
    }
    return List<String>.from(_byGym[gymId] ?? const <String>[]);
  }

  /// Resolves [key] to the asset path. Unknown keys fall back to global/default.
  String resolvePath(String key) {
    final normalized = _normalize(key);
    if (!_loaded) {
      unawaited(load());
    }
    final exists = _allKeys.contains(normalized);
    if (!exists && kDebugMode) {
      debugPrint('[AvatarCatalog] unknown key "$key" – using global/default');
    }
    final resolved = exists ? normalized : 'global/default';
    return 'assets/avatars/' + resolved + '.png';
  }

  bool exists(String key) {
    final normalized = _normalize(key);
    if (!_loaded) {
      unawaited(load());
    }
    return _allKeys.contains(normalized);
  }

  String _normalize(String key) {
    // migration: bare "default" -> "global/default"
    if (!key.contains('/')) {
      return 'global/' + key;
    }
    return key;
  }
}


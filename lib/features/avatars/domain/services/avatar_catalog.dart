import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Representation of an avatar asset.
class AvatarItem {
  const AvatarItem(this.key, this.path);

  final String key;
  final String path;
}

/// Catalog of avatar assets discovered at runtime from the [AssetManifest].
///
/// Keys use the form `<namespace>/<name>` where `namespace` is either `global`
/// or the gym document id. Paths returned from [resolvePath] are full asset
/// paths such as `assets/avatars/global/default.png`.
class AvatarCatalog {
  AvatarCatalog._();

  static final AvatarCatalog instance = AvatarCatalog._();

  bool _loaded = false;
  bool _loading = false;
  bool _diagDone = false;

  bool get isReady => _loaded;

  final Map<String, AvatarItem> _items = <String, AvatarItem>{
    'global/default':
        const AvatarItem('global/default', 'assets/avatars/global/default.png'),
    'global/default2':
        const AvatarItem('global/default2', 'assets/avatars/global/default2.png'),
  };

  final List<AvatarItem> _global = <AvatarItem>[
    const AvatarItem('global/default', 'assets/avatars/global/default.png'),
    const AvatarItem('global/default2', 'assets/avatars/global/default2.png'),
  ];

  final Map<String, List<AvatarItem>> _gym = <String, List<AvatarItem>>{};
  final Set<String> _warned = <String>{};

  Future<void> warmUp() async {
    if (_loaded || _loading) return;
    _loading = true;
    try {
      String manifestStr;
      try {
        manifestStr = await rootBundle.loadString('AssetManifest.json');
      } catch (_) {
        manifestStr = await rootBundle.loadString('AssetManifest.bin.json');
      }
      final Map<String, dynamic> manifest =
          json.decode(manifestStr) as Map<String, dynamic>;
      const prefix = 'assets/avatars/';
      const ext = '.png';
      for (final path in manifest.keys) {
        if (!path.startsWith(prefix) || !path.endsWith(ext)) continue;
        final rel = path.substring(prefix.length, path.length - ext.length);
        final slash = rel.indexOf('/');
        if (slash == -1) continue;
        final namespace = rel.substring(0, slash);
        final name = rel.substring(slash + 1);
        final key = '$namespace/$name';
        final item = AvatarItem(key, path);
        _items[key] = item;
        if (namespace == 'global') {
          _global.add(item);
        } else {
          final list = _gym.putIfAbsent(namespace, () => <AvatarItem>[]);
          list.add(item);
        }
      }
      _global.sort((a, b) => a.key.compareTo(b.key));
      for (final list in _gym.values) {
        list.sort((a, b) => a.key.compareTo(b.key));
      }
      if (kDebugMode && !_diagDone) {
        if (!_items.containsKey('global/default')) {
          debugPrint(
              '[AvatarCatalog] missing assets/avatars/global/default.png – app restart required: flutter clean && flutter pub get && flutter run');
        }
        if (!_items.containsKey('global/default2')) {
          debugPrint(
              '[AvatarCatalog] missing assets/avatars/global/default2.png – app restart required: flutter clean && flutter pub get && flutter run');
        }
        _diagDone = true;
      }
    } finally {
      _loaded = true;
      _loading = false;
    }
  }

  String resolvePath(String key, {String? currentGymId}) {
    if (!_loaded) unawaited(warmUp());
    String lookup = key;
    AvatarItem? item = _items[lookup];
    if (item == null) {
      // legacy mapping
      if (lookup == 'default') {
        lookup = 'global/default';
        item = _items[lookup];
      } else if (lookup == 'default2') {
        lookup = 'global/default2';
        item = _items[lookup];
      } else if (!lookup.contains('/')) {
        if (currentGymId != null) {
          final gymKey = '$currentGymId/$lookup';
          item = _items[gymKey];
          if (item != null) lookup = gymKey;
        }
        item ??= _items['global/$lookup'];
        if (item != null) lookup = item.key;
      }
    }
    item ??= _items['global/default'];
    if (kDebugMode && !_warned.contains(key) && !_items.containsKey(key)) {
      debugPrint('[AvatarCatalog] unknown key "$key" – using global/default');
      _warned.add(key);
    }
    return item?.path ?? 'assets/avatars/global/default.png';
  }

  List<AvatarItem> listGlobal() {
    if (!_loaded) unawaited(warmUp());
    return List<AvatarItem>.unmodifiable(_global);
  }

  List<AvatarItem> listGym(String gymDocId) {
    if (!_loaded) unawaited(warmUp());
    return List<AvatarItem>.unmodifiable(_gym[gymDocId] ?? const []);
  }

  ({List<AvatarItem> global, List<AvatarItem> gym}) allForContext(String gymDocId) {
    return (global: listGlobal(), gym: listGym(gymDocId));
  }

  void resetForTests() {
    _loaded = false;
    _loading = false;
    _diagDone = false;
    _items
      ..clear()
      ..addAll({
        'global/default': const AvatarItem(
            'global/default', 'assets/avatars/global/default.png'),
        'global/default2': const AvatarItem(
            'global/default2', 'assets/avatars/global/default2.png'),
      });
    _global
      ..clear()
      ..addAll([
        const AvatarItem('global/default', 'assets/avatars/global/default.png'),
        const AvatarItem('global/default2', 'assets/avatars/global/default2.png'),
      ]);
    _gym.clear();
    _warned.clear();
  }
}

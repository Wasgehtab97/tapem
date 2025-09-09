import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tapem/core/utils/avatar_assets.dart';

/// Representation of an avatar asset.
class AvatarItem {
  const AvatarItem(this.key, this.path);

  final String key;
  final String path;
}

/// Catalog of avatar assets discovered at runtime from the [AssetManifest].
///
/// Keys use the form `<namespace>/<name>` where `namespace` is either `global`
/// or the gym document id. Paths returned from [pathForKey] are full asset
/// paths such as `assets/avatars/global/default.png`.
class AvatarCatalog {
  AvatarCatalog._();

  static final AvatarCatalog instance = AvatarCatalog._();

  bool _loaded = false;
  bool _loading = false;
  bool _diagDone = false;

  bool get isReady => _loaded;

  final Map<String, AvatarItem> _items = <String, AvatarItem>{};

  final List<AvatarItem> _global = <AvatarItem>[];

  final Map<String, List<AvatarItem>> _gym = <String, List<AvatarItem>>{};

  static const AvatarItem _placeholder =
      AvatarItem('placeholder', 'assets/images/logo.png');

  bool _isValidGymNamespace(String name) {
    final gymPattern = RegExp(r'^[A-Za-z0-9_-]+$');
    return gymPattern.hasMatch(name);
  }

  Future<void> warmUp({AssetBundle? bundle}) async {
    if (_loaded || _loading) return;
    _loading = true;
    final AssetBundle b = bundle ?? rootBundle;
    try {
      String manifestStr;
      try {
        manifestStr = await b.loadString('AssetManifest.json');
      } catch (_) {
        manifestStr = await b.loadString('AssetManifest.bin.json');
      }
      final Map<String, dynamic> manifest =
          json.decode(manifestStr) as Map<String, dynamic>;
      const prefix = 'assets/avatars/';
      const ext = '.png';
      final ignored = <String>{};
      final items = <String, AvatarItem>{};
      final global = <AvatarItem>[];
      final gym = <String, List<AvatarItem>>{};
      for (final path in manifest.keys) {
        if (!path.startsWith(prefix) || !path.endsWith(ext)) continue;
        final rel = path.substring(prefix.length, path.length - ext.length);
        final slash = rel.indexOf('/');
        if (slash == -1) continue;
        final namespace = rel.substring(0, slash);
        final name = rel.substring(slash + 1);
        if (namespace != 'global' && !_isValidGymNamespace(namespace)) {
          ignored.add(namespace);
          continue;
        }
        final key = '$namespace/$name';
        final item = AvatarItem(key, path);
        items[key] = item;
        if (namespace == 'global') {
          global.add(item);
        } else {
          final list = gym.putIfAbsent(namespace, () => <AvatarItem>[]);
          list.add(item);
        }
      }
      global.sort((a, b) => a.key.compareTo(b.key));
      for (final list in gym.values) {
        list.sort((a, b) => a.key.compareTo(b.key));
      }
      _items
        ..clear()
        ..addAll(items);
      _global
        ..clear()
        ..addAll(global);
      _gym
        ..clear()
        ..addAll(gym);
      if (kDebugMode && !_diagDone) {
        if (!items.containsKey('global/default')) {
          debugPrint('[AvatarCatalog] manifest_missing: assets/avatars/global/default.png');
        }
        if (!items.containsKey('global/default2')) {
          debugPrint('[AvatarCatalog] manifest_missing: assets/avatars/global/default2.png');
        }
        final gymParts = gym.entries
            .map((e) => 'gym(${e.key})=${e.value.length}')
            .join(', ');
        debugPrint(
            '[AvatarCatalog] warmup: global=${global.length}${gymParts.isNotEmpty ? ', ' + gymParts : ''}, ignored_non_gym_dirs=${ignored.toList()}');
        _diagDone = true;
      }
    } finally {
      _loaded = true;
      _loading = false;
    }
  }

  String pathForKey(String key) {
    if (!_loaded) unawaited(warmUp());
    AvatarItem? item = _items[key];
    if (item == null) {
      final name = key.split('/').last;
      item = _items['global/$name'];
    }
    item ??= _items[AvatarKeys.globalDefault];
    item ??= _placeholder;
    return item.path;
  }

  bool hasKey(String key) => _items.containsKey(key);

  bool hasPath(String path) =>
      _items.values.any((element) => element.path == path);

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
    _items.clear();
    _global.clear();
    _gym.clear();
  }
}

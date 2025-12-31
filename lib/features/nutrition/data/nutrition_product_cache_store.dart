import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/models/nutrition_product.dart';

class NutritionProductCacheStore {
  static const _metaKey = 'nutrition_product_cache_meta';
  static const _indexKey = 'nutrition_product_cache_index';

  final SharedPreferences _prefs;
  final int maxEntries;

  NutritionProductCacheStore(this._prefs, {this.maxEntries = 200});

  String _itemKey(String barcode) => 'nutrition_product_cache/$barcode';

  NutritionProduct? get(String barcode) {
    final raw = _prefs.getString(_itemKey(barcode));
    if (raw == null || raw.isEmpty) return null;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      _touch(barcode);
      return NutritionProduct.fromMap(barcode, data);
    } catch (_) {
      return null;
    }
  }

  Future<void> put(NutritionProduct product) async {
    final data = product.toMap()
      ..remove('updatedAt'); // cache store does not need timestamps
    await _prefs.setString(_itemKey(product.barcode), jsonEncode(data));
    _touch(product.barcode);
    _pruneIfNeeded();
  }

  void _touch(String barcode) {
    final meta = _loadMeta();
    meta[barcode] = DateTime.now().millisecondsSinceEpoch;
    _saveMeta(meta);
    final index = _prefs.getStringList(_indexKey) ?? <String>[];
    if (!index.contains(barcode)) {
      _prefs.setStringList(_indexKey, [...index, barcode]);
    }
  }

  void _pruneIfNeeded() {
    final index = _prefs.getStringList(_indexKey) ?? <String>[];
    if (index.length <= maxEntries) return;
    final meta = _loadMeta();
    final sorted = [...index];
    sorted.sort((a, b) => (meta[a] ?? 0).compareTo(meta[b] ?? 0));
    final toRemove = sorted.take(sorted.length - maxEntries).toList();
    for (final barcode in toRemove) {
      _prefs.remove(_itemKey(barcode));
      meta.remove(barcode);
    }
    final remaining = index.where((b) => !toRemove.contains(b)).toList();
    _prefs.setStringList(_indexKey, remaining);
    _saveMeta(meta);
  }

  Map<String, int> _loadMeta() {
    final raw = _prefs.getString(_metaKey);
    if (raw == null || raw.isEmpty) return <String, int>{};
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      return data.map((k, v) => MapEntry(k, v as int));
    } catch (_) {
      return <String, int>{};
    }
  }

  void _saveMeta(Map<String, int> meta) {
    _prefs.setString(_metaKey, jsonEncode(meta));
  }
}

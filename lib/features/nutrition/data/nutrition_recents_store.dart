import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tapem/core/providers/shared_preferences_provider.dart';
import 'package:tapem/features/nutrition/domain/models/nutrition_product.dart';
import 'package:tapem/features/nutrition/domain/models/nutrition_recent_item.dart';

final nutritionRecentsStoreProvider = Provider<NutritionRecentsStore>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return NutritionRecentsStore(prefs);
});

class NutritionRecentsStore {
  static const _key = 'nutrition_recents_v1';
  static const _limit = 60;

  final SharedPreferences _prefs;

  NutritionRecentsStore(this._prefs);

  List<NutritionRecentItem> load() {
    final raw = _prefs.getStringList(_key) ?? const [];
    final items = <NutritionRecentItem>[];
    for (final s in raw) {
      final item = NutritionRecentItem.tryDecode(s);
      if (item == null) continue;
      if (item.name.trim().isEmpty) continue;
      items.add(item);
    }
    return items;
  }

  Future<void> add({
    required NutritionProduct product,
    required double grams,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final item = NutritionRecentItem(
      barcode: product.barcode.trim().isEmpty ? null : product.barcode.trim(),
      name: product.name,
      kcalPer100: product.kcalPer100,
      proteinPer100: product.proteinPer100,
      carbsPer100: product.carbsPer100,
      fatPer100: product.fatPer100,
      lastGrams: grams <= 0 ? 100 : grams,
      lastUsedAtMs: now,
    );

    final existing = load();
    final key = item.stableKey();
    final deduped = <NutritionRecentItem>[];
    final seen = <String>{};

    if (key != null) {
      seen.add(key);
    }
    deduped.add(item);

    for (final e in existing) {
      final k = e.stableKey();
      if (k != null && seen.contains(k)) continue;
      if (k != null) seen.add(k);
      deduped.add(e);
      if (deduped.length >= _limit) break;
    }

    await _prefs.setStringList(
      _key,
      deduped.map(NutritionRecentItem.encode).toList(growable: false),
    );
  }
}

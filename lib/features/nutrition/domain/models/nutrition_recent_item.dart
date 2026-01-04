import 'dart:convert';

import 'package:tapem/features/nutrition/domain/models/nutrition_product.dart';

class NutritionRecentItem {
  final String? barcode;
  final String name;
  final int kcalPer100;
  final int proteinPer100;
  final int carbsPer100;
  final int fatPer100;
  final double lastGrams;
  final int lastUsedAtMs;

  const NutritionRecentItem({
    required this.barcode,
    required this.name,
    required this.kcalPer100,
    required this.proteinPer100,
    required this.carbsPer100,
    required this.fatPer100,
    required this.lastGrams,
    required this.lastUsedAtMs,
  });

  NutritionProduct toProduct() {
    return NutritionProduct(
      barcode: barcode ?? '',
      name: name,
      kcalPer100: kcalPer100,
      proteinPer100: proteinPer100,
      carbsPer100: carbsPer100,
      fatPer100: fatPer100,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(lastUsedAtMs),
    );
  }

  Map<String, Object?> toJson() => {
        'barcode': barcode,
        'name': name,
        'kcalPer100': kcalPer100,
        'proteinPer100': proteinPer100,
        'carbsPer100': carbsPer100,
        'fatPer100': fatPer100,
        'lastGrams': lastGrams,
        'lastUsedAtMs': lastUsedAtMs,
      };

  static NutritionRecentItem fromJson(Map<String, Object?> json) {
    return NutritionRecentItem(
      barcode: (json['barcode'] as String?)?.trim().isEmpty == true
          ? null
          : json['barcode'] as String?,
      name: (json['name'] as String?)?.trim() ?? '',
      kcalPer100: (json['kcalPer100'] as num?)?.toInt() ?? 0,
      proteinPer100: (json['proteinPer100'] as num?)?.toInt() ?? 0,
      carbsPer100: (json['carbsPer100'] as num?)?.toInt() ?? 0,
      fatPer100: (json['fatPer100'] as num?)?.toInt() ?? 0,
      lastGrams: (json['lastGrams'] as num?)?.toDouble() ?? 100,
      lastUsedAtMs: (json['lastUsedAtMs'] as num?)?.toInt() ??
          DateTime.now().millisecondsSinceEpoch,
    );
  }

  static String encode(NutritionRecentItem item) => jsonEncode(item.toJson());

  static NutritionRecentItem? tryDecode(String raw) {
    try {
      final parsed = jsonDecode(raw);
      if (parsed is! Map) return null;
      return fromJson(parsed.cast<String, Object?>());
    } catch (_) {
      return null;
    }
  }

  String? stableKey() {
    final b = barcode?.trim();
    if (b != null && b.isNotEmpty) return 'b:$b';
    final n = name.trim();
    if (n.isEmpty) return null;
    return 'n:${n.toLowerCase()}';
  }
}


import 'package:cloud_firestore/cloud_firestore.dart';

class NutritionProduct {
  final String barcode;
  final String name;
  final int kcalPer100;
  final int proteinPer100;
  final int carbsPer100;
  final int fatPer100;
  final DateTime? updatedAt;

  const NutritionProduct({
    required this.barcode,
    required this.name,
    required this.kcalPer100,
    required this.proteinPer100,
    required this.carbsPer100,
    required this.fatPer100,
    required this.updatedAt,
  });

  factory NutritionProduct.fromMap(String barcode, Map<String, dynamic> data) {
    return NutritionProduct(
      barcode: barcode,
      name: data['name'] as String? ?? '',
      kcalPer100: (data['kcalPer100'] as num?)?.round() ?? 0,
      proteinPer100: (data['proteinPer100'] as num?)?.round() ?? 0,
      carbsPer100: (data['carbsPer100'] as num?)?.round() ?? 0,
      fatPer100: (data['fatPer100'] as num?)?.round() ?? 0,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'kcalPer100': kcalPer100,
    'proteinPer100': proteinPer100,
    'carbsPer100': carbsPer100,
    'fatPer100': fatPer100,
    if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
  };
}

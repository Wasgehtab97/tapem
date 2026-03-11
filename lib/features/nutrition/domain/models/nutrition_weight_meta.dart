import 'package:cloud_firestore/cloud_firestore.dart';

class NutritionWeightMeta {
  final double kg;
  final String dateKey;
  final DateTime? updatedAt;

  const NutritionWeightMeta({
    required this.kg,
    required this.dateKey,
    required this.updatedAt,
  });

  factory NutritionWeightMeta.fromMap(Map<String, dynamic> data) {
    return NutritionWeightMeta(
      kg: (data['kg'] as num?)?.toDouble() ?? 0,
      dateKey: data['dateKey'] as String? ?? '',
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'kg': kg,
    'dateKey': dateKey,
    if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
  };
}

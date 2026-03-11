import 'package:cloud_firestore/cloud_firestore.dart';

class NutritionWeightLog {
  final String dateKey;
  final double kg;
  final String source;
  final DateTime? updatedAt;

  const NutritionWeightLog({
    required this.dateKey,
    required this.kg,
    required this.source,
    required this.updatedAt,
  });

  factory NutritionWeightLog.fromMap(
    String dateKey,
    Map<String, dynamic> data,
  ) {
    return NutritionWeightLog(
      dateKey: dateKey,
      kg: (data['kg'] as num?)?.toDouble() ?? 0,
      source: data['source'] as String? ?? 'manual',
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'kg': kg,
    'source': source,
    if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
  };
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'nutrition_macros.dart';

class NutritionGoal {
  final String dateKey;
  final int kcal;
  final NutritionMacros macros;
  final String source;
  final DateTime? updatedAt;

  const NutritionGoal({
    required this.dateKey,
    required this.kcal,
    required this.macros,
    required this.source,
    required this.updatedAt,
  });

  factory NutritionGoal.fromMap(String dateKey, Map<String, dynamic> data) {
    return NutritionGoal(
      dateKey: dateKey,
      kcal: (data['kcal'] as num?)?.round() ?? 0,
      macros: NutritionMacros.fromMap(data['macros'] as Map<String, dynamic>?),
      source: data['source'] as String? ?? 'manual',
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'kcal': kcal,
    'macros': macros.toMap(),
    'source': source,
    if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
  };
}

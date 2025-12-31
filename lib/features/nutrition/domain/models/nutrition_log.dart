import 'package:cloud_firestore/cloud_firestore.dart';
import 'nutrition_entry.dart';
import 'nutrition_totals.dart';

class NutritionLog {
  final String dateKey;
  final NutritionTotals total;
  final List<NutritionEntry> entries;
  final String status;
  final DateTime? updatedAt;

  const NutritionLog({
    required this.dateKey,
    required this.total,
    required this.entries,
    required this.status,
    required this.updatedAt,
  });

  factory NutritionLog.fromMap(String dateKey, Map<String, dynamic> data) {
    final rawEntries = (data['entries'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();
    return NutritionLog(
      dateKey: dateKey,
      total: NutritionTotals.fromMap(data['total'] as Map<String, dynamic>?),
      entries: rawEntries.map(NutritionEntry.fromMap).toList(),
      status: data['status'] as String? ?? 'under',
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'total': total.toMap(),
    'entries': entries.map((e) => e.toMap()).toList(),
    'status': status,
    if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
  };
}

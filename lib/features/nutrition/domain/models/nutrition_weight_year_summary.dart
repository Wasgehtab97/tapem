import 'package:cloud_firestore/cloud_firestore.dart';

class NutritionWeightYearSummary {
  static final RegExp _dateKeyPattern = RegExp(r'^\d{8}$');

  final int year;
  final Map<String, NutritionWeightYearDay> days;

  const NutritionWeightYearSummary({required this.year, required this.days});

  factory NutritionWeightYearSummary.fromMap(
    int year,
    Map<String, dynamic> data,
  ) {
    final rawDays = _extractRawDays(data);
    final days = <String, NutritionWeightYearDay>{};
    for (final entry in rawDays.entries) {
      final value = entry.value;
      if (value is num) {
        days[entry.key] = NutritionWeightYearDay(kg: value.toDouble());
      } else if (value is Map) {
        final dayData = Map<String, dynamic>.from(value);
        days[entry.key] = NutritionWeightYearDay.fromMap(dayData);
      }
    }
    return NutritionWeightYearSummary(year: year, days: days);
  }

  static Map<String, dynamic> _extractRawDays(Map<String, dynamic> data) {
    final rawDays = data['days'];
    if (rawDays is Map) {
      return Map<String, dynamic>.from(rawDays);
    }

    // Legacy fallback: older payloads stored date keys at the root level.
    final legacyDays = <String, dynamic>{};
    for (final entry in data.entries) {
      if (_dateKeyPattern.hasMatch(entry.key)) {
        legacyDays[entry.key] = entry.value;
      }
    }
    return legacyDays;
  }

  Map<String, dynamic> toMap() => {
    'days': days.map((k, v) => MapEntry(k, v.toMap())),
  };
}

class NutritionWeightYearDay {
  final double kg;
  final DateTime? updatedAt;

  const NutritionWeightYearDay({required this.kg, this.updatedAt});

  factory NutritionWeightYearDay.fromMap(Map<String, dynamic> data) {
    final rawUpdatedAt = data['updatedAt'];
    DateTime? updatedAt;
    if (rawUpdatedAt is Timestamp) {
      updatedAt = rawUpdatedAt.toDate();
    } else if (rawUpdatedAt is DateTime) {
      updatedAt = rawUpdatedAt;
    }

    return NutritionWeightYearDay(
      kg: (data['kg'] as num?)?.toDouble() ?? 0,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'kg': kg,
    if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
  };
}

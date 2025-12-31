import 'package:intl/intl.dart';

String toNutritionDateKey(DateTime d) {
  final local = d.toLocal();
  final normalized = DateTime(local.year, local.month, local.day);
  return DateFormat('yyyyMMdd').format(normalized);
}

String nutritionDateKeyFromParts(int year, int month, int day) {
  final normalized = DateTime(year, month, day);
  return DateFormat('yyyyMMdd').format(normalized);
}

DateTime nutritionStartOfDay(DateTime d) {
  final local = d.toLocal();
  return DateTime(local.year, local.month, local.day);
}

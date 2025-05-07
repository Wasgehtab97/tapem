// lib/core/utils/formatters.dart

import 'package:intl/intl.dart';

class AppFormatters {
  static String formatDate(DateTime date) {
    return DateFormat.yMMMd().format(date); // z. B. “Jul 20, 2025”
  }

  static String formatNumber(num value) {
    return NumberFormat.decimalPattern().format(value);
  }
}

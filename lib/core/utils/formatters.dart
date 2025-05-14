// lib/core/utils/formatters.dart

import 'package:intl/intl.dart';

/// Stellt gemeinsame Formatierungsfunktionen zur Verfügung.
class AppFormatters {
  /// Formatiert ein Datum im Stil “20. Jul 2025” (lokalisierte Variante).
  static String formatDate(DateTime date) {
    return DateFormat.yMMMd().format(date);
  }

  /// Formatiert eine Zahl entsprechend dem aktuellen Locale (Tausender-Trennzeichen etc.).
  static String formatNumber(num value) {
    return NumberFormat.decimalPattern().format(value);
  }
}

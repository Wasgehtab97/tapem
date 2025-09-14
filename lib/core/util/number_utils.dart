import 'package:flutter/foundation.dart';

/// Parses a [String] containing a number using lenient rules.
///
/// - Accepts both comma and dot as decimal separators.
/// - Ignores whitespace and thin spaces used as thousand separators.
/// - Returns `null` if the input cannot be parsed to a [double].
///
double? parseLenientDouble(String input) {
  final cleaned = input
      .trim()
      .replaceAll(RegExp(r'[\s\u00A0\u202F]'), '')
      .replaceAll(',', '.');
  if (cleaned.isEmpty) return null;
  return double.tryParse(cleaned);
}

/// Utility for validating cardio speed. Visible for testing.
@visibleForTesting
bool isValidSpeed(String input, double max) {
  final v = parseLenientDouble(input);
  if (v == null) return false;
  return v > 0 && v <= max;
}

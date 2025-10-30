import 'package:meta/meta.dart';

/// Utilities to sanitize and normalize member numbers for Firestore queries.
@immutable
class MemberNumberFormatter {
  const MemberNumberFormatter._();

  /// Returns only the digits contained in [value].
  static String digitsOnly(String value) {
    return value.replaceAll(RegExp(r'[^0-9]'), '');
  }

  /// Normalizes a [value] to exactly four digits, padding with leading zeros
  /// and truncating to the last four digits if necessary.
  static String normalize(String value) {
    final digits = digitsOnly(value);
    if (digits.isEmpty) {
      return '0000';
    }
    final padded = digits.padLeft(4, '0');
    return padded.substring(padded.length - 4);
  }
}

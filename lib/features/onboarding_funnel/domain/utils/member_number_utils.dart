import 'package:meta/meta.dart';

/// Normalizes any onboarding funnel member number input to a four digit string.
///
/// Non-numeric characters are removed and the remaining digits are left-padded
/// with zeros up to four characters. If more than four digits are provided, the
/// last four digits are kept.
///
/// Returns `null` when the input does not contain any digits.
@visibleForTesting
String? normalizeMemberNumber(String value) {
  final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
  if (digitsOnly.isEmpty) {
    return null;
  }
  final padded = digitsOnly.padLeft(4, '0');
  return padded.substring(padded.length - 4);
}

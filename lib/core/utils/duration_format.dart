import 'package:flutter/material.dart';

/// Formats [duration] into a human readable string.
/// - >=1h: "H h M min"
/// - >=1min: "M min"
/// - else: "S s"
String formatDuration(Duration duration, {Locale? locale}) {
  final l = locale?.languageCode ?? 'en';
  if (duration.inHours >= 1) {
    final h = duration.inHours;
    final m = duration.inMinutes % 60;
    return l == 'de' ? '$h h $m min' : '$h h $m min';
  }
  if (duration.inMinutes >= 1) {
    final m = duration.inMinutes;
    return l == 'de' ? '$m min' : '$m min';
  }
  final s = duration.inSeconds;
  return l == 'de' ? '$s s' : '$s s';
}

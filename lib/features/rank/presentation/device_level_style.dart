import 'package:flutter/material.dart';

/// Provides background colors for the device page depending on a user's level.
class DeviceLevelStyle {
  static const Color level1Background = Color(0xFFE3F2FD); // light blue
  static const Color level2Background = Color(0xFFE8F5E9); // light green
  static const Color level3Background = Color(0xFFFFF8E1); // light gold

  /// Returns the background color for the given level.
  /// Levels above 3 reuse the color of level 3 for now.
  static Color backgroundFor(int level) {
    if (level <= 1) return level1Background;
    if (level == 2) return level2Background;
    return level3Background;
  }
}

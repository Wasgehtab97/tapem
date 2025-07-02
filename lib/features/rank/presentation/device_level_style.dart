import 'package:flutter/material.dart';

/// Provides widget colors for the device page depending on a user's level.
class DeviceLevelStyle {
  static const Color level1Widget = Color(0xFFE3F2FD); // light blue
  static const Color level2Widget = Color(0xFFE8F5E9); // light green
  static const Color level3Widget = Color(0xFFFFF8E1); // light gold

  /// Returns the widget color for the given level.
  /// Levels above 3 reuse the color of level 3 for now.
  static Color widgetColorFor(int level) {
    if (level <= 1) return level1Widget;
    if (level == 2) return level2Widget;
    return level3Widget;
  }

  // Deprecated background method for backward compatibility.
  static Color backgroundFor(int level) => widgetColorFor(level);
}

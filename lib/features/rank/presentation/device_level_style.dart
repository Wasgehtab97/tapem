import 'package:flutter/material.dart';

/// Provides widget colors for the device page depending on a user's level.
class DeviceLevelStyle {
  // Use more saturated colors so the user level is clearly visible.
  static const Color level1Widget = Color(0xFF42A5F5); // vivid blue
  static const Color level2Widget = Color(0xFF66BB6A); // vivid green
  static const Color level3Widget = Color(0xFFFFCA28); // vivid amber

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

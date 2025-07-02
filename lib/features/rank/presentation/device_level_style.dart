import 'package:flutter/material.dart';

/// Provides widget styling for the device page depending on a user's level.
class DeviceLevelStyle {
  // Keep the old colors for potential fallback usage.
  static const Color level1Widget = Color(0xFF42A5F5); // vivid blue
  static const Color level2Widget = Color(0xFF66BB6A); // vivid green
  static const Color level3Widget = Color(0xFFFFCA28); // vivid amber

  // Image assets used as background for widgets depending on the level.
  static const String level1Image = 'assets/images/lvl1.png';
  static const String level2Image = 'assets/images/lvl2.png';
  static const String level3Image = 'assets/images/lvl3.png';

  /// Returns the widget color for the given level.
  /// Levels above 3 reuse the color of level 3 for now.
  static Color widgetColorFor(int level) {
    if (level <= 1) return level1Widget;
    if (level == 2) return level2Widget;
    return level3Widget;
  }

  /// Returns the background image path for the given level.
  /// Levels above 3 reuse the image of level 3 for now.
  static String _imageFor(int level) {
    if (level <= 1) return level1Image;
    if (level == 2) return level2Image;
    return level3Image;
  }

  /// Decoration that applies the appropriate background image.
  static BoxDecoration widgetDecorationFor(int level) {
    return BoxDecoration(
      image: DecorationImage(
        image: AssetImage(_imageFor(level)),
        fit: BoxFit.cover,
      ),
    );
  }

  // Deprecated background method for backward compatibility.
  static Color backgroundFor(int level) => widgetColorFor(level);
}

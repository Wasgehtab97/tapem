import 'package:flutter/material.dart';
import 'package:tapem/core/theme/design_tokens.dart';

/// Provides widget styling for the device page depending on a user's level.
class DeviceLevelStyle {
  // Keep the old colors for potential fallback usage.
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

  /// Decoration for device widgets following the app's gradient style.
  ///
  /// The optional [opacity] and [brightness] parameters are ignored but kept
  /// for backward compatibility with existing calls.
  static BoxDecoration widgetDecorationFor(
    int level, {
    double opacity = 1.0,
    double brightness = -0.6,
  }) {
    return BoxDecoration(
      gradient: AppGradients.primary,
      borderRadius: BorderRadius.circular(AppRadius.card),
    );
  }

  // Deprecated background method for backward compatibility.
  static Color backgroundFor(int level) => widgetColorFor(level);
}

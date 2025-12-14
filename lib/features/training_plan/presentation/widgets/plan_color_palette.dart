import 'package:flutter/material.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';

class PlanColorPalette {
  static const int colorCount = 7;

  static List<Color> colors(ThemeData theme) {
    final brand = theme.extension<AppBrandTheme>();
    final base = brand?.outline ?? theme.colorScheme.secondary;
    return <Color>[
      base,
      const Color(0xFF00E5FF), // Cyan
      const Color(0xFF7C4DFF), // Violett
      const Color(0xFFFF4081), // Pink
      const Color(0xFFFFC400), // Amber
      const Color(0xFF69F0AE), // Mint
      const Color(0xFFFF6E40), // Orange
    ];
  }

  static Color colorForIndex(int index, ThemeData theme) {
    final all = colors(theme);
    if (all.isEmpty) return theme.colorScheme.secondary;
    final safeIndex = index % all.length;
    return all[safeIndex];
  }
}


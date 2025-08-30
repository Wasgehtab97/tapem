import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Calculates the WCAG contrast ratio between [a] and [b].
/// Formula: (L1 + 0.05) / (L2 + 0.05) where L1 is lighter luminance.
double contrastRatio(Color a, Color b) {
  final l1 = a.computeLuminance();
  final l2 = b.computeLuminance();
  final bright = math.max(l1, l2);
  final dark = math.min(l1, l2);
  return (bright + 0.05) / (dark + 0.05);
}

class ColorContrast {
  final Color background;
  final Color foreground;
  const ColorContrast(this.background, this.foreground);
}

/// Returns a foreground colour with maximum contrast on [background].
/// If necessary, subtly darkens or lightens the background before
/// finalising the foreground colour.  The returned [ColorContrast]
/// contains the potentially adjusted background and the chosen foreground.
ColorContrast ensureForeground(Color background, {double minRatio = 4.5}) {
  final black = contrastRatio(background, Colors.black);
  final white = contrastRatio(background, Colors.white);
  Color fg = black > white ? Colors.black : Colors.white;
  double contrast = math.max(black, white);
  Color bg = background;
  if (contrast < minRatio) {
    final overlay = bg.computeLuminance() > 0.5 ? Colors.black : Colors.white;
    double opacity = 0.05;
    while (contrast < minRatio && opacity <= 0.4) {
      bg = Color.alphaBlend(overlay.withOpacity(opacity), bg);
      contrast = contrastRatio(bg, fg);
      opacity += 0.05;
    }
  }
  return ColorContrast(bg, fg);
}

class GradientContrast {
  final Color start;
  final Color end;
  final Color foreground;
  const GradientContrast(this.start, this.end, this.foreground);
}

/// Computes a foreground colour for a gradient defined by [start] and [end].
/// Evaluates contrast at the start, end and midpoint colours and picks the
/// foreground that maximises the minimum contrast across them.  If the
/// resulting contrast falls below [minRatio], the gradient colours are
/// subtly darkened or lightened until the threshold is met.
GradientContrast ensureGradientForeground(Color start, Color end,
    {double minRatio = 4.5}) {
  Color s = start;
  Color e = end;
  Color mid = Color.lerp(s, e, 0.5)!;
  Color bestFg = Colors.white;
  double bestMin = 0;
  for (final candidate in [Colors.black, Colors.white]) {
    final ratios = [
      contrastRatio(s, candidate),
      contrastRatio(e, candidate),
      contrastRatio(mid, candidate),
    ];
    final minContrast = ratios.reduce(math.min);
    if (minContrast > bestMin) {
      bestMin = minContrast;
      bestFg = candidate;
    }
  }
  if (bestMin < minRatio) {
    final overlay =
        (s.computeLuminance() + e.computeLuminance() + mid.computeLuminance()) /
                    3 >
                0.5
            ? Colors.black
            : Colors.white;
    double opacity = 0.05;
    while (bestMin < minRatio && opacity <= 0.4) {
      s = Color.alphaBlend(overlay.withOpacity(opacity), s);
      e = Color.alphaBlend(overlay.withOpacity(opacity), e);
      mid = Color.lerp(s, e, 0.5)!;
      bestMin = [
        contrastRatio(s, bestFg),
        contrastRatio(e, bestFg),
        contrastRatio(mid, bestFg),
      ].reduce(math.min);
      opacity += 0.05;
    }
  }
  return GradientContrast(s, e, bestFg);
}

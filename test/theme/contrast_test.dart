import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/core/theme/contrast.dart';
import 'package:tapem/core/theme/design_tokens.dart';

void main() {
  group('contrast', () {
    test('mint/turquoise', () {
      final r = ensureForeground(AppColors.accentMint);
      expect(contrastRatio(r.background, r.foreground) >= 4.5, isTrue);
    });
    test('magenta', () {
      final r = ensureForeground(MagentaColors.primary600);
      expect(contrastRatio(r.background, r.foreground) >= 4.5, isTrue);
    });
    test('club aktiv', () {
      final r = ensureForeground(ClubAktivColors.primary600);
      expect(contrastRatio(r.background, r.foreground) >= 4.5, isTrue);
    });
    test('very light custom', () {
      final r = ensureForeground(const Color(0xFFF5F5F5));
      expect(contrastRatio(r.background, r.foreground) >= 4.5, isTrue);
    });
    test('gradient', () {
      final g = ensureGradientForeground(
        AppColors.accentMint,
        AppColors.accentTurquoise,
      );
      final ratios = [
        contrastRatio(g.start, g.foreground),
        contrastRatio(g.end, g.foreground),
        contrastRatio(Color.lerp(g.start, g.end, 0.5)!, g.foreground),
      ];
      expect(ratios.every((r) => r >= 4.5), isTrue);
    });
  });
}

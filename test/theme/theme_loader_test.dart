import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/core/theme/theme_loader.dart';
import 'package:tapem/features/gym/domain/models/branding.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/theme/theme.dart';
import 'package:tapem/core/theme/brand_on_colors.dart';

void main() {
  group('ThemeLoader', () {
    test('gym_01 without branding uses magenta theme', () {
      final loader = ThemeLoader()..loadDefault();
      loader.applyBranding('gym_01', null);
      expect(loader.theme.colorScheme.primary, MagentaColors.primary600);
    });

    test('gym_01 with branding applies custom colors', () {
      final loader = ThemeLoader()..loadDefault();
      loader.applyBranding(
        'gym_01',
        Branding(primaryColor: '#123456', secondaryColor: '#654321'),
      );
      expect(loader.theme.colorScheme.primary,
          equals(const Color(0xFF123456)));
      expect(loader.theme.colorScheme.secondary,
          equals(const Color(0xFF654321)));
    });

    test('Club Aktiv without branding uses red/orange theme', () {
      final loader = ThemeLoader()..loadDefault();
      loader.applyBranding('Club Aktiv', null);
      expect(loader.theme.colorScheme.primary, ClubAktivColors.primary600);
    });

    test('Club Aktiv with branding applies custom colors', () {
      final loader = ThemeLoader()..loadDefault();
      loader.applyBranding(
        'Club Aktiv',
        Branding(primaryColor: '#123456', secondaryColor: '#654321'),
      );
      expect(loader.theme.colorScheme.primary,
          equals(const Color(0xFF123456)));
      expect(loader.theme.colorScheme.secondary,
          equals(const Color(0xFF654321)));
    });

    test('other gyms keep default theme', () {
      final loader = ThemeLoader()..loadDefault();
      loader.applyBranding('other', null);
      expect(loader.theme.colorScheme.primary, AppColors.accentMint);
    });

    test('BrandOnColors tokens are black', () {
      final loader = ThemeLoader()..loadDefault();
      final on = loader.theme.extension<BrandOnColors>()!;
      expect(on.onPrimary, Colors.black);
      expect(on.onSecondary, Colors.black);
      expect(on.onGradient, Colors.black);
      expect(on.onCta, Colors.black);
    });

    test('gym_01 surfaces are normalised to reference luminance', () {
      final loader = ThemeLoader()..loadDefault();
      loader.applyBranding('gym_01', null);

      final anchor = MagentaTones.brightnessAnchor;
      final grad = AppGradients.brandGradient;
      final gradLum =
          grad.colors.map((c) => c.computeLuminance()).reduce((a, b) => a + b) /
              grad.colors.length;
      expect((gradLum - anchor).abs(), lessThanOrEqualTo(0.02));
      expect(
          (MagentaTones.surface1.computeLuminance() - anchor).abs(),
          lessThanOrEqualTo(0.02));
      expect(
          (MagentaTones.surface2.computeLuminance() - (anchor + 0.025)).abs(),
          lessThanOrEqualTo(0.02));
      expect(
          (MagentaTones.control.computeLuminance() - (anchor + 0.01)).abs(),
          lessThanOrEqualTo(0.02));
    });

    test('Club Aktiv surfaces are normalised to reference luminance', () {
      final loader = ThemeLoader()..loadDefault();
      loader.applyBranding('Club Aktiv', null);

      final anchor = ClubAktivTones.brightnessAnchor;
      final grad = AppGradients.brandGradient;
      final gradLum =
          grad.colors.map((c) => c.computeLuminance()).reduce((a, b) => a + b) /
              grad.colors.length;
      expect((gradLum - anchor).abs(), lessThanOrEqualTo(0.02));
      expect(
          (ClubAktivTones.surface1.computeLuminance() - anchor).abs(),
          lessThanOrEqualTo(0.02));
      expect(
          (ClubAktivTones.surface2.computeLuminance() -
                  (anchor + 0.025))
              .abs(),
          lessThanOrEqualTo(0.02));
      expect(
          (ClubAktivTones.control.computeLuminance() - (anchor + 0.01))
              .abs(),
          lessThanOrEqualTo(0.02));
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/core/theme/theme_loader.dart';
import 'package:tapem/features/gym/domain/models/branding.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/theme/theme.dart';

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

    test('other gyms keep default theme', () {
      final loader = ThemeLoader()..loadDefault();
      loader.applyBranding('other', null);
      expect(loader.theme.colorScheme.primary, AppColors.accentMint);
    });
  });
}

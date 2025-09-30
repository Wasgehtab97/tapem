import 'package:flutter/material.dart';

import 'design_tokens.dart';

/// Identifiers for built-in app brand themes that can be applied manually.
enum BrandThemeId { mintTurquoise, magentaViolet }

extension BrandThemeIdX on BrandThemeId {
  String get storageValue {
    switch (this) {
      case BrandThemeId.mintTurquoise:
        return 'mintTurquoise';
      case BrandThemeId.magentaViolet:
        return 'magentaViolet';
    }
  }

  static BrandThemeId? fromStorage(String value) {
    switch (value) {
      case 'mintTurquoise':
        return BrandThemeId.mintTurquoise;
      case 'magentaViolet':
        return BrandThemeId.magentaViolet;
    }
    return null;
  }
}

/// Describes a preset theme that can be applied without fetching branding data.
class BrandThemePreset {
  const BrandThemePreset({
    required this.id,
    required this.nameKey,
    required this.primary,
    required this.secondary,
    required this.gradientStart,
    required this.gradientEnd,
    required this.focus,
    this.useMagentaTokens = false,
    this.useClubAktivTokens = false,
  });

  final BrandThemeId id;
  final String nameKey;
  final Color primary;
  final Color secondary;
  final Color gradientStart;
  final Color gradientEnd;
  final Color focus;
  final bool useMagentaTokens;
  final bool useClubAktivTokens;
}

/// Built-in presets that users can manually select.
class BrandThemePresets {
  static const BrandThemePreset mintTurquoise = BrandThemePreset(
    id: BrandThemeId.mintTurquoise,
    nameKey: 'settingsThemeMintTurquoise',
    primary: AppColors.accentMint,
    secondary: AppColors.accentTurquoise,
    gradientStart: AppColors.accentMint,
    gradientEnd: AppColors.accentTurquoise,
    focus: AppColors.accentTurquoise,
  );

  static const BrandThemePreset magentaViolet = BrandThemePreset(
    id: BrandThemeId.magentaViolet,
    nameKey: 'settingsThemeMagentaViolet',
    primary: MagentaColors.primary600,
    secondary: MagentaColors.secondary,
    gradientStart: MagentaColors.primary500,
    gradientEnd: MagentaColors.secondary,
    focus: MagentaColors.focus,
    useMagentaTokens: true,
  );

  static const List<BrandThemePreset> all = [
    mintTurquoise,
    magentaViolet,
  ];

  static BrandThemePreset of(BrandThemeId id) {
    switch (id) {
      case BrandThemeId.mintTurquoise:
        return mintTurquoise;
      case BrandThemeId.magentaViolet:
        return magentaViolet;
    }
  }
}

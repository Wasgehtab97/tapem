import 'package:flutter/material.dart';

import 'brand_on_colors.dart';
import 'design_tokens.dart';

/// Identifiers for built-in app brand themes that can be applied manually.
enum BrandThemeId {
  mintTurquoise,
  magentaViolet,
  redOrange,
  blackWhite,
}

extension BrandThemeIdX on BrandThemeId {
  String get storageValue {
    switch (this) {
      case BrandThemeId.mintTurquoise:
        return 'mintTurquoise';
      case BrandThemeId.magentaViolet:
        return 'magentaViolet';
      case BrandThemeId.redOrange:
        return 'redOrange';
      case BrandThemeId.blackWhite:
        return 'blackWhite';
    }
  }

  static BrandThemeId? fromStorage(String value) {
    switch (value) {
      case 'mintTurquoise':
        return BrandThemeId.mintTurquoise;
      case 'magentaViolet':
        return BrandThemeId.magentaViolet;
      case 'redOrange':
        return BrandThemeId.redOrange;
      case 'blackWhite':
        return BrandThemeId.blackWhite;
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
    this.onColors,
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
  final BrandOnColors? onColors;
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

  static const BrandThemePreset redOrange = BrandThemePreset(
    id: BrandThemeId.redOrange,
    nameKey: 'settingsThemeRedOrange',
    primary: ClubAktivColors.primary600,
    secondary: ClubAktivColors.secondary,
    gradientStart: ClubAktivColors.primary500,
    gradientEnd: ClubAktivColors.primary600,
    focus: ClubAktivColors.focus,
    useClubAktivTokens: true,
  );

  static const BrandThemePreset blackWhite = BrandThemePreset(
    id: BrandThemeId.blackWhite,
    nameKey: 'settingsThemeBlackWhite',
    primary: Colors.white,
    secondary: Colors.black,
    gradientStart: Colors.black,
    gradientEnd: Color(0xFF3D3D3D),
    focus: Colors.white,
    onColors: const BrandOnColors(
      onPrimary: Colors.black,
      onSecondary: Colors.white,
      onGradient: Colors.white,
      onCta: Colors.white,
    ),
  );

  static const List<BrandThemePreset> all = [
    mintTurquoise,
    magentaViolet,
    redOrange,
    blackWhite,
  ];

  static BrandThemePreset of(BrandThemeId id) {
    switch (id) {
      case BrandThemeId.mintTurquoise:
        return mintTurquoise;
      case BrandThemeId.magentaViolet:
        return magentaViolet;
      case BrandThemeId.redOrange:
        return redOrange;
      case BrandThemeId.blackWhite:
        return blackWhite;
    }
  }
}

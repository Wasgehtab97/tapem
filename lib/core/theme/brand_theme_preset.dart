import 'package:flutter/material.dart';

import 'brand_on_colors.dart';
import 'design_tokens.dart';

/// Identifiers for built-in app brand themes that can be applied manually.
enum BrandThemeId {
  mintTurquoise,
  magentaViolet,
  redOrange,
  blackWhite,
  azureSapphire,
  amberSunset,
  forestEmerald,
  royalPlum,
  neonLime,
  copperBronze,
  arcticSky,
  emberInferno,
  cyberGrape,
  citrusPunch,
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
      case BrandThemeId.azureSapphire:
        return 'azureSapphire';
      case BrandThemeId.amberSunset:
        return 'amberSunset';
      case BrandThemeId.forestEmerald:
        return 'forestEmerald';
      case BrandThemeId.royalPlum:
        return 'royalPlum';
      case BrandThemeId.neonLime:
        return 'neonLime';
      case BrandThemeId.copperBronze:
        return 'copperBronze';
      case BrandThemeId.arcticSky:
        return 'arcticSky';
      case BrandThemeId.emberInferno:
        return 'emberInferno';
      case BrandThemeId.cyberGrape:
        return 'cyberGrape';
      case BrandThemeId.citrusPunch:
        return 'citrusPunch';
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
      case 'azureSapphire':
        return BrandThemeId.azureSapphire;
      case 'amberSunset':
        return BrandThemeId.amberSunset;
      case 'forestEmerald':
        return BrandThemeId.forestEmerald;
      case 'royalPlum':
        return BrandThemeId.royalPlum;
      case 'neonLime':
        return BrandThemeId.neonLime;
      case 'copperBronze':
        return BrandThemeId.copperBronze;
      case 'arcticSky':
        return BrandThemeId.arcticSky;
      case 'emberInferno':
        return BrandThemeId.emberInferno;
      case 'cyberGrape':
        return BrandThemeId.cyberGrape;
      case 'citrusPunch':
        return BrandThemeId.citrusPunch;
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
    this.background,
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
  final Color? background;
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
    secondary: Colors.white,
    gradientStart: Colors.white,
    gradientEnd: Colors.white,
    focus: Colors.white,
    onColors: BrandOnColors(
      onPrimary: Colors.black,
      onSecondary: Colors.white,
      onGradient: Colors.white,
      onCta: Colors.white,
    ),
    background: Colors.black,
  );

  static const BrandThemePreset azureSapphire = BrandThemePreset(
    id: BrandThemeId.azureSapphire,
    nameKey: 'settingsThemeAzureSapphire',
    primary: PresetBrandColors.azurePrimary,
    secondary: PresetBrandColors.azureSecondary,
    gradientStart: PresetBrandColors.azureGradientStart,
    gradientEnd: PresetBrandColors.azureGradientEnd,
    focus: PresetBrandColors.azureFocus,
  );

  static const BrandThemePreset amberSunset = BrandThemePreset(
    id: BrandThemeId.amberSunset,
    nameKey: 'settingsThemeAmberSunset',
    primary: PresetBrandColors.amberPrimary,
    secondary: PresetBrandColors.amberSecondary,
    gradientStart: PresetBrandColors.amberGradientStart,
    gradientEnd: PresetBrandColors.amberGradientEnd,
    focus: PresetBrandColors.amberFocus,
  );

  static const BrandThemePreset forestEmerald = BrandThemePreset(
    id: BrandThemeId.forestEmerald,
    nameKey: 'settingsThemeForestEmerald',
    primary: PresetBrandColors.forestPrimary,
    secondary: PresetBrandColors.forestSecondary,
    gradientStart: PresetBrandColors.forestGradientStart,
    gradientEnd: PresetBrandColors.forestGradientEnd,
    focus: PresetBrandColors.forestFocus,
  );

  static const BrandThemePreset royalPlum = BrandThemePreset(
    id: BrandThemeId.royalPlum,
    nameKey: 'settingsThemeRoyalPlum',
    primary: PresetBrandColors.royalPrimary,
    secondary: PresetBrandColors.royalSecondary,
    gradientStart: PresetBrandColors.royalGradientStart,
    gradientEnd: PresetBrandColors.royalGradientEnd,
    focus: PresetBrandColors.royalFocus,
  );

  static const BrandThemePreset neonLime = BrandThemePreset(
    id: BrandThemeId.neonLime,
    nameKey: 'settingsThemeNeonLime',
    primary: PresetBrandColors.neonPrimary,
    secondary: PresetBrandColors.neonSecondary,
    gradientStart: PresetBrandColors.neonGradientStart,
    gradientEnd: PresetBrandColors.neonGradientEnd,
    focus: PresetBrandColors.neonFocus,
    onColors: BrandOnColors(
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onGradient: Colors.black,
      onCta: Colors.black,
    ),
  );

  static const BrandThemePreset copperBronze = BrandThemePreset(
    id: BrandThemeId.copperBronze,
    nameKey: 'settingsThemeCopperBronze',
    primary: PresetBrandColors.copperPrimary,
    secondary: PresetBrandColors.copperSecondary,
    gradientStart: PresetBrandColors.copperGradientStart,
    gradientEnd: PresetBrandColors.copperGradientEnd,
    focus: PresetBrandColors.copperFocus,
  );

  static const BrandThemePreset arcticSky = BrandThemePreset(
    id: BrandThemeId.arcticSky,
    nameKey: 'settingsThemeArcticSky',
    primary: PresetBrandColors.arcticPrimary,
    secondary: PresetBrandColors.arcticSecondary,
    gradientStart: PresetBrandColors.arcticGradientStart,
    gradientEnd: PresetBrandColors.arcticGradientEnd,
    focus: PresetBrandColors.arcticFocus,
    onColors: BrandOnColors(
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onGradient: Colors.black,
      onCta: Colors.black,
    ),
  );

  static const BrandThemePreset emberInferno = BrandThemePreset(
    id: BrandThemeId.emberInferno,
    nameKey: 'settingsThemeEmberInferno',
    primary: PresetBrandColors.emberPrimary,
    secondary: PresetBrandColors.emberSecondary,
    gradientStart: PresetBrandColors.emberGradientStart,
    gradientEnd: PresetBrandColors.emberGradientEnd,
    focus: PresetBrandColors.emberFocus,
  );

  static const BrandThemePreset cyberGrape = BrandThemePreset(
    id: BrandThemeId.cyberGrape,
    nameKey: 'settingsThemeCyberGrape',
    primary: PresetBrandColors.cyberPrimary,
    secondary: PresetBrandColors.cyberSecondary,
    gradientStart: PresetBrandColors.cyberGradientStart,
    gradientEnd: PresetBrandColors.cyberGradientEnd,
    focus: PresetBrandColors.cyberFocus,
  );

  static const BrandThemePreset citrusPunch = BrandThemePreset(
    id: BrandThemeId.citrusPunch,
    nameKey: 'settingsThemeCitrusPunch',
    primary: PresetBrandColors.citrusPrimary,
    secondary: PresetBrandColors.citrusSecondary,
    gradientStart: PresetBrandColors.citrusGradientStart,
    gradientEnd: PresetBrandColors.citrusGradientEnd,
    focus: PresetBrandColors.citrusFocus,
    onColors: BrandOnColors(
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onGradient: Colors.black,
      onCta: Colors.black,
    ),
  );

  static const List<BrandThemePreset> all = [
    mintTurquoise,
    magentaViolet,
    redOrange,
    blackWhite,
    azureSapphire,
    amberSunset,
    forestEmerald,
    royalPlum,
    neonLime,
    copperBronze,
    arcticSky,
    emberInferno,
    cyberGrape,
    citrusPunch,
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
      case BrandThemeId.azureSapphire:
        return azureSapphire;
      case BrandThemeId.amberSunset:
        return amberSunset;
      case BrandThemeId.forestEmerald:
        return forestEmerald;
      case BrandThemeId.royalPlum:
        return royalPlum;
      case BrandThemeId.neonLime:
        return neonLime;
      case BrandThemeId.copperBronze:
        return copperBronze;
      case BrandThemeId.arcticSky:
        return arcticSky;
      case BrandThemeId.emberInferno:
        return emberInferno;
      case BrandThemeId.cyberGrape:
        return cyberGrape;
      case BrandThemeId.citrusPunch:
        return citrusPunch;
    }
  }
}

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
  cyberpunkNeon,
  animeBloom,
  flameInferno,
  waterTribe,
  airNomads,
  earthKingdom,
  midnightGold,
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
      case BrandThemeId.cyberpunkNeon:
        return 'cyberpunkNeon';
      case BrandThemeId.animeBloom:
        return 'animeBloom';
      case BrandThemeId.flameInferno:
        return 'flameInferno';
      case BrandThemeId.waterTribe:
        return 'waterTribe';
      case BrandThemeId.airNomads:
        return 'airNomads';
      case BrandThemeId.earthKingdom:
        return 'earthKingdom';
      case BrandThemeId.midnightGold:
        return 'midnightGold';
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
      case 'cyberpunkNeon':
        return BrandThemeId.cyberpunkNeon;
      case 'animeBloom':
        return BrandThemeId.animeBloom;
      case 'flameInferno':
        return BrandThemeId.flameInferno;
      case 'waterTribe':
        return BrandThemeId.waterTribe;
      case 'airNomads':
        return BrandThemeId.airNomads;
      case 'earthKingdom':
        return BrandThemeId.earthKingdom;
      case 'midnightGold':
        return BrandThemeId.midnightGold;
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
    this.useCyberpunkTokens = false,
    this.useAnimeTokens = false,
    this.useFlameTokens = false,
    this.useWaterTokens = false,
    this.useAirTokens = false,
    this.useEarthTokens = false,
    this.useMidnightTokens = false,
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
  final bool useCyberpunkTokens;
  final bool useAnimeTokens;
  final bool useFlameTokens;
  final bool useWaterTokens;
  final bool useAirTokens;
  final bool useEarthTokens;
  final bool useMidnightTokens;
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

  /// High-energy neon cyberpunk palette.
  static const BrandThemePreset cyberpunkNeon = BrandThemePreset(
    id: BrandThemeId.cyberpunkNeon,
    nameKey: 'settingsThemeCyberpunkNeon',
    // Etwas dunkleres Cyan als Primärfarbe,
    // damit der Verlauf mehr Tiefe bekommt.
    primary: Color(0xFF00CFEA),
    secondary: Color(0xFFFF2AA5), // neon magenta
    gradientStart: Color(0xFF00E5FF),
    // Leicht violetteres Ende für einen filmischeren Neon-Verlauf.
    gradientEnd: Color(0xFFB300FF),
    focus: Color(0xFF8CFBFF),
    useCyberpunkTokens: true,
    onColors: BrandOnColors(
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onGradient: Colors.black,
      onCta: Colors.black,
    ),
    background: Color(0xFF050813),
  );

  /// Soft, anime-inspired sakura & sky gradient.
  static const BrandThemePreset animeBloom = BrandThemePreset(
    id: BrandThemeId.animeBloom,
    nameKey: 'settingsThemeAnimeBloom',
    primary: PresetBrandColors.animePrimary,
    secondary: PresetBrandColors.animeSecondary,
    gradientStart: PresetBrandColors.animeGradientStart,
    gradientEnd: PresetBrandColors.animeGradientEnd,
    focus: PresetBrandColors.animeFocus,
    useAnimeTokens: true,
    onColors: BrandOnColors(
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onGradient: Colors.black,
      onCta: Colors.black,
    ),
    background: Color(0xFF090813),
  );

  /// Intense flame gradient with deep embers and bright highlights.
  static const BrandThemePreset flameInferno = BrandThemePreset(
    id: BrandThemeId.flameInferno,
    nameKey: 'settingsThemeFlameInferno',
    primary: PresetBrandColors.flamePrimary,
    secondary: PresetBrandColors.flameSecondary,
    gradientStart: PresetBrandColors.flameGradientStart,
    gradientEnd: PresetBrandColors.flameGradientEnd,
    focus: PresetBrandColors.flameFocus,
    useFlameTokens: true,
    onColors: BrandOnColors(
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onGradient: Colors.black,
      onCta: Colors.black,
    ),
    background: Color(0xFF120608),
  );

  /// Water Tribe-inspired deep ocean theme.
  static const BrandThemePreset waterTribe = BrandThemePreset(
    id: BrandThemeId.waterTribe,
    nameKey: 'settingsThemeWaterTribe',
    primary: PresetBrandColors.waterPrimary,
    secondary: PresetBrandColors.waterSecondary,
    gradientStart: PresetBrandColors.waterGradientStart,
    gradientEnd: PresetBrandColors.waterGradientEnd,
    focus: PresetBrandColors.waterFocus,
    useWaterTokens: true,
    onColors: BrandOnColors(
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onGradient: Colors.white,
      onCta: Colors.white,
    ),
    background: Color(0xFF020915),
  );

  /// Air Nomads-inspired light sky theme.
  static const BrandThemePreset airNomads = BrandThemePreset(
    id: BrandThemeId.airNomads,
    nameKey: 'settingsThemeAirNomads',
    primary: PresetBrandColors.airPrimary,
    secondary: PresetBrandColors.airSecondary,
    gradientStart: PresetBrandColors.airGradientStart,
    gradientEnd: PresetBrandColors.airGradientEnd,
    focus: PresetBrandColors.airFocus,
    useAirTokens: true,
    onColors: BrandOnColors(
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onGradient: Colors.black,
      onCta: Colors.black,
    ),
    background: Color(0xFF090A12),
  );

  /// Earth Kingdom-inspired deep green theme.
  static const BrandThemePreset earthKingdom = BrandThemePreset(
    id: BrandThemeId.earthKingdom,
    nameKey: 'settingsThemeEarthKingdom',
    primary: PresetBrandColors.earthPrimary,
    secondary: PresetBrandColors.earthSecondary,
    gradientStart: PresetBrandColors.earthGradientStart,
    gradientEnd: PresetBrandColors.earthGradientEnd,
    focus: PresetBrandColors.earthFocus,
    useEarthTokens: true,
    onColors: BrandOnColors(
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onGradient: Colors.white,
      onCta: Colors.white,
    ),
    background: Color(0xFF020B06),
  );
  
  /// Midnight Gold - Premium deep black & gold theme.
  static const BrandThemePreset midnightGold = BrandThemePreset(
    id: BrandThemeId.midnightGold,
    nameKey: 'settingsThemeMidnightGold',
    primary: Color(0xFFC5A059),
    secondary: Color(0xFF8C6E4A),
    gradientStart: Color(0xFFD4AF37),
    gradientEnd: Color(0xFF704214),
    focus: Color(0xFFFFDF00),
    useMidnightTokens: true,
    onColors: BrandOnColors(
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onGradient: Colors.black,
      onCta: Colors.black,
    ),
    background: Color(0xFF050505),
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
    cyberpunkNeon,
    animeBloom,
    flameInferno,
    waterTribe,
    airNomads,
    earthKingdom,
    midnightGold,
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
      case BrandThemeId.cyberpunkNeon:
        return cyberpunkNeon;
      case BrandThemeId.animeBloom:
        return animeBloom;
      case BrandThemeId.flameInferno:
        return flameInferno;
      case BrandThemeId.waterTribe:
        return waterTribe;
      case BrandThemeId.airNomads:
        return airNomads;
      case BrandThemeId.earthKingdom:
        return earthKingdom;
      case BrandThemeId.midnightGold:
        return midnightGold;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/gym/domain/models/branding.dart';
import '../providers/auth_providers.dart';
import '../providers/branding_provider.dart';
import '../providers/theme_preference_provider.dart';
import 'app_brand_theme.dart';
import 'brand_on_colors.dart';
import 'brand_theme_preset.dart';
import 'design_tokens.dart';
import 'theme.dart';

/// Lädt dynamisch Themes je nach Gym.
class ThemeLoader extends ChangeNotifier {
  ThemeData _currentTheme = AppTheme.mintDarkTheme;
  ThemeData get theme => _currentTheme;

  /// Setzt das Standard-Dark-Theme.
  void loadDefault() {
    _applyBrandColors(
      primary: AppColors.accentMint,
      secondary: AppColors.accentTurquoise,
      gradStart: AppColors.accentMint,
      gradEnd: AppColors.accentTurquoise,
      focus: AppColors.accentTurquoise,
    );
    notifyListeners();
  }

  /// Wendet Branding-Daten auf das aktuelle Theme an.
  void applyBranding(
    String? gymId,
    Branding? branding, {
    BrandThemeId? overridePreset,
  }) {
    if (overridePreset != null) {
      _applyPreset(BrandThemePresets.of(overridePreset));
      notifyListeners();
      return;
    }

    if (gymId == 'lifthouse_koblenz') {
      if (branding == null) {
        _applyMagentaDefaults();
        notifyListeners();
        return;
      }
      final primary = branding.primaryColor != null
          ? _parseHex(branding.primaryColor!)
          : MagentaColors.primary600;
      final secondary = branding.secondaryColor != null
          ? _parseHex(branding.secondaryColor!)
          : MagentaColors.secondary;
      final gradStart = branding.gradientStart != null
          ? _parseHex(branding.gradientStart!)
          : MagentaColors.primary500;
      final gradEnd = branding.gradientEnd != null
          ? _parseHex(branding.gradientEnd!)
          : MagentaColors.secondary;
      _applyBrandColors(
        primary: primary,
        secondary: secondary,
        gradStart: gradStart,
        gradEnd: gradEnd,
        focus: MagentaColors.focus,
        useMagenta: true,
      );
      notifyListeners();
      return;
    }

    if (gymId == 'Club Aktiv' || gymId == 'FitnessFirst MyZeil') {
      if (branding == null) {
        _applyClubAktivDefaults();
        notifyListeners();
        return;
      }
      final primary = branding.primaryColor != null
          ? _parseHex(branding.primaryColor!)
          : ClubAktivColors.primary600;
      final secondary = branding.secondaryColor != null
          ? _parseHex(branding.secondaryColor!)
          : ClubAktivColors.secondary;
      final gradStart = branding.gradientStart != null
          ? _parseHex(branding.gradientStart!)
          : ClubAktivColors.primary500;
      final gradEnd = branding.gradientEnd != null
          ? _parseHex(branding.gradientEnd!)
          : ClubAktivColors.primary600;
      _applyBrandColors(
        primary: primary,
        secondary: secondary,
        gradStart: gradStart,
        gradEnd: gradEnd,
        focus: ClubAktivColors.focus,
        useClubAktiv: true,
      );
      notifyListeners();
      return;
    }

    if (branding == null ||
        branding.primaryColor == null ||
        branding.secondaryColor == null) {
      loadDefault();
      return;
    }
    final primary = _parseHex(branding.primaryColor!);
    final accent = _parseHex(branding.secondaryColor!);
    final gradStart = branding.gradientStart != null
        ? _parseHex(branding.gradientStart!)
        : primary;
    final gradEnd = branding.gradientEnd != null
        ? _parseHex(branding.gradientEnd!)
        : accent;
    _applyBrandColors(
      primary: primary,
      secondary: accent,
      gradStart: gradStart,
      gradEnd: gradEnd,
      focus: accent,
    );
    notifyListeners();
  }

  void _applyMagentaDefaults() {
    _applyPreset(BrandThemePresets.magentaViolet);
  }

  void _applyClubAktivDefaults() {
    _applyBrandColors(
      primary: ClubAktivColors.primary600,
      secondary: ClubAktivColors.secondary,
      gradStart: ClubAktivColors.primary500,
      gradEnd: ClubAktivColors.primary600,
      focus: ClubAktivColors.focus,
      useClubAktiv: true,
    );
    ClubAktivTones.normalizeFromGradient(AppGradients.brandGradient);
  }

  void _applyPreset(BrandThemePreset preset) {
    if (preset.id == BrandThemeId.blackWhite) {
      _applyBlackWhitePreset(preset);
      return;
    }

    _applyBrandColors(
      primary: preset.primary,
      secondary: preset.secondary,
      gradStart: preset.gradientStart,
      gradEnd: preset.gradientEnd,
      focus: preset.focus,
      useMagenta: preset.useMagentaTokens,
      useClubAktiv: preset.useClubAktivTokens,
      useCyberpunk: preset.useCyberpunkTokens,
      useAnime: preset.useAnimeTokens,
      useFlame: preset.useFlameTokens,
      useWater: preset.useWaterTokens,
      useAir: preset.useAirTokens,
      useEarth: preset.useEarthTokens,
      useMidnight: preset.useMidnightTokens,
      onColors: preset.onColors,
      background: preset.background,
    );
    if (preset.useMagentaTokens) {
      MagentaTones.normalizeFromGradient(AppGradients.brandGradient);
    } else if (preset.useClubAktivTokens) {
      ClubAktivTones.normalizeFromGradient(AppGradients.brandGradient);
    }
  }

  void _applyBlackWhitePreset(BrandThemePreset preset) {
    _currentTheme = AppTheme.neutralTheme;
    final onColors = preset.onColors ??
        const BrandOnColors(
          onPrimary: Colors.black,
          onSecondary: Colors.white,
          onGradient: Colors.white,
          onCta: Colors.white,
        );
    AppGradients.setBrandGradient(preset.gradientStart, preset.gradientEnd);
    AppGradients.setCtaGlow(preset.focus);
    _currentTheme = _currentTheme.copyWith(
      colorScheme: _currentTheme.colorScheme.copyWith(
        onPrimary: onColors.onPrimary,
        onSecondary: onColors.onSecondary,
      ),
    );
    _attachBrandTheme(
      focus: preset.focus,
      onColors: onColors,
      useNeutral: true,
    );
  }

  Color _parseHex(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  void _applyBrandColors({
    required Color primary,
    required Color secondary,
    required Color gradStart,
    required Color gradEnd,
    required Color focus,
    bool useMagenta = false,
    bool useClubAktiv = false,
    bool useCyberpunk = false,
    bool useAnime = false,
    bool useFlame = false,
    bool useWater = false,
    bool useAir = false,
    bool useEarth = false,
    bool useMidnight = false,
    BrandOnColors? onColors,
    Color? background,
  }) {
    // Optional spezialisierte Flächen:
    // - Cyberpunk: etwas hellerer, leicht cyan-getönter Hintergrund.
    // - Anime: weicher, minimal aufgehellter Hintergrund mit Sakura-Tint.
    // - Flame: dunkle Glut mit warmen Highlights.
    // - Water/Air/Earth: leicht getönte Surfaces passend zum Element.
    // Für alle anderen Themes bleiben Surface-Werte unverändert.
    Color? resolvedBackground = background;
    Color? resolvedSurface;
    Color? resolvedSurface2;
    if (useCyberpunk) {
      resolvedBackground ??= const Color(0xFF050813);
      resolvedSurface = Tone.color(resolvedBackground, 0.06);
      resolvedSurface2 = Tone.color(resolvedBackground, 0.1);
    } else if (useAnime) {
      resolvedBackground ??= const Color(0xFF090813);
      resolvedSurface = Tone.color(resolvedBackground, 0.05);
      resolvedSurface2 = Tone.color(resolvedBackground, 0.08);
    } else if (useFlame) {
      resolvedBackground ??= const Color(0xFF120608);
      resolvedSurface = Tone.color(resolvedBackground, 0.07);
      resolvedSurface2 = Tone.color(resolvedBackground, 0.11);
    } else if (useWater || useAir || useEarth) {
      resolvedBackground ??= background ?? AppColors.background;
      resolvedSurface = Tone.color(resolvedBackground, 0.04);
      resolvedSurface2 = Tone.color(resolvedBackground, 0.07);
    } else if (useMidnight) {
      resolvedBackground ??= const Color(0xFF050505);
      resolvedSurface = Tone.color(resolvedBackground, 0.05);
      resolvedSurface2 = Tone.color(resolvedBackground, 0.08);
    }

    _currentTheme = AppTheme.customTheme(
      primary: primary,
      secondary: secondary,
      // Standardmäßig bleiben Hintergrund und Flächen global neutral (schwarz).
      // Vollständig manuelle Themes (z. B. Cyberpunk) können optional einen
      // eigenen Hintergrund + Flächentöne setzen.
      background: resolvedBackground ?? background,
      surface: resolvedSurface,
      surface2: resolvedSurface2,
    );
    AppGradients.setBrandGradient(gradStart, gradEnd);
    AppGradients.setCtaGlow(focus);

    final resolvedOnColors = onColors ??
        const BrandOnColors(
          onPrimary: Colors.black,
          onSecondary: Colors.black,
          onGradient: Colors.black,
          onCta: Colors.black,
        );

    final scheme = _currentTheme.colorScheme.copyWith(
      onPrimary: resolvedOnColors.onPrimary,
      onSecondary: resolvedOnColors.onSecondary,
    );
    _currentTheme = _currentTheme.copyWith(colorScheme: scheme);
    _attachBrandTheme(
      focus: focus,
      onColors: resolvedOnColors,
      useMagenta: useMagenta,
      useClubAktiv: useClubAktiv,
      useCyberpunk: useCyberpunk,
      useAnime: useAnime,
      useFlame: useFlame,
      useWater: useWater,
      useAir: useAir,
      useEarth: useEarth,
      useMidnight: useMidnight,
    );

    if (useMagenta) {
      MagentaTones.normalizeFromGradient(AppGradients.brandGradient);
    } else if (useClubAktiv) {
      ClubAktivTones.normalizeFromGradient(AppGradients.brandGradient);
    }
  }

  void _attachBrandTheme({
    required Color focus,
    required BrandOnColors onColors,
    bool useMagenta = false,
    bool useClubAktiv = false,
    bool useCyberpunk = false,
    bool useAnime = false,
    bool useFlame = false,
    bool useWater = false,
    bool useAir = false,
    bool useEarth = false,
    bool useMidnight = false,
    bool useNeutral = false,
  }) {
    final ext = useMagenta
        ? AppBrandTheme.magenta()
        : useClubAktiv
            ? AppBrandTheme.clubAktiv()
            : useNeutral
                ? AppBrandTheme.defaultTheme().copyWith(
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Colors.black, Colors.black],
                    ),
                    outlineGradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Colors.white, Colors.white],
                    ),
                    outline: Colors.white,
                    outlineColorFallback: Colors.white,
                    outlineShadow: const [
                      BoxShadow(color: Colors.white24, blurRadius: 12),
                    ],
                    shadow: const [
                      BoxShadow(
                        color: Colors.black87,
                        blurRadius: 16,
                        offset: Offset(0, 8),
                      ),
                    ],
                    pressedOverlay: Colors.white10,
                    focusRing: focus,
                    onBrand: onColors.onCta,
                  )
                : useCyberpunk
                    ? AppBrandTheme.cyberpunk()
                    : useAnime
                        ? AppBrandTheme.anime()
                        : useFlame
                            ? AppBrandTheme.flame()
                            : useWater
                                ? AppBrandTheme.water()
                                : useAir
                                    ? AppBrandTheme.air()
                                    : useEarth
                                        ? AppBrandTheme.earth()
                                        : useMidnight
                                            ? AppBrandTheme.midnight()
                                            : AppBrandTheme.defaultTheme().copyWith(
                                            gradient: AppGradients.brandGradient,
                                            outlineGradient:
                                                AppGradients.brandGradient,
                                            focusRing: focus,
                                            onBrand: onColors.onCta,
                                          );
    _currentTheme = _currentTheme.copyWith(extensions: [ext, onColors]);
  }
}

final themeLoaderProvider = ChangeNotifierProvider<ThemeLoader>((ref) {
  final loader = ThemeLoader()..loadDefault();
  
  // Listen to branding changes and update theme
  ref.listen<BrandingProvider>(brandingProvider, (previous, next) {
    final preferences = ref.read(themePreferenceProvider);
    loader.applyBranding(
      next.gymId,
      next.branding,
      overridePreset: preferences.override,
    );
  }, fireImmediately: true);
  
  // Listen to preference changes and update theme
  ref.listen<ThemePreferenceProvider>(themePreferenceProvider, (previous, next) {
    final branding = ref.read(brandingProvider);
    loader.applyBranding(
      branding.gymId,
      branding.branding,
      overridePreset: next.override,
    );
  });
  
  ref.onDispose(loader.dispose);
  return loader;
});

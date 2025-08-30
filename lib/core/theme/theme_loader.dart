import 'package:flutter/material.dart';

import '../../features/gym/domain/models/branding.dart';
import 'design_tokens.dart';
import 'theme.dart';
import 'app_brand_theme.dart';
import 'brand_on_colors.dart';
import 'contrast.dart';

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
  void applyBranding(String? gymId, Branding? branding) {
    if (gymId == 'gym_01') {
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

    if (gymId == 'Club Aktiv') {
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
    _applyBrandColors(
      primary: MagentaColors.primary600,
      secondary: MagentaColors.secondary,
      gradStart: MagentaColors.primary500,
      gradEnd: MagentaColors.secondary,
      focus: MagentaColors.focus,
      useMagenta: true,
    );
    MagentaTones.normalizeFromGradient(AppGradients.brandGradient);
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
  }) {
    final p = ensureForeground(primary);
    final s = ensureForeground(secondary);
    final g = ensureGradientForeground(gradStart, gradEnd);

    _currentTheme = AppTheme.customTheme(
      primary: p.background,
      secondary: s.background,
    );
    AppGradients.setBrandGradient(g.start, g.end);
    AppGradients.setCtaGlow(focus);

    final onColors = BrandOnColors(
      onPrimary: p.foreground,
      onSecondary: s.foreground,
      onGradient: g.foreground,
      onCta: g.foreground,
    );

    final scheme = _currentTheme.colorScheme.copyWith(
      onPrimary: onColors.onPrimary,
      onSecondary: onColors.onSecondary,
    );
    _currentTheme = _currentTheme.copyWith(colorScheme: scheme);
    _attachBrandTheme(
      focus: focus,
      onColors: onColors,
      useMagenta: useMagenta,
      useClubAktiv: useClubAktiv,
    );
  }

  void _attachBrandTheme({
    required Color focus,
    required BrandOnColors onColors,
    bool useMagenta = false,
    bool useClubAktiv = false,
  }) {
    final ext = useMagenta
        ? AppBrandTheme.magenta()
        : useClubAktiv
            ? AppBrandTheme.clubAktiv()
            : AppBrandTheme.defaultTheme().copyWith(
                gradient: AppGradients.brandGradient,
                outlineGradient: AppGradients.brandGradient,
                focusRing: focus,
                onBrand: onColors.onCta,
              );
    _currentTheme = _currentTheme.copyWith(extensions: [ext, onColors]);
  }
}

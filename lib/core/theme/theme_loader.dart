import 'package:flutter/material.dart';

import '../../features/gym/domain/models/branding.dart';
import 'design_tokens.dart';
import 'theme.dart';
import 'app_brand_theme.dart';

/// Lädt dynamisch Themes je nach Gym.
class ThemeLoader extends ChangeNotifier {
  ThemeData _currentTheme = AppTheme.mintDarkTheme;
  ThemeData get theme => _currentTheme;

  /// Setzt das Standard-Dark-Theme.
  void loadDefault() {
    _currentTheme = AppTheme.mintDarkTheme;
    AppGradients.setBrandGradient(
      AppColors.accentMint,
      AppColors.accentTurquoise,
    );
    AppGradients.setCtaGlow(AppColors.accentMint);
    _attachBrandTheme(
      focus: AppColors.accentTurquoise,
      foreground: AppColors.textPrimary,
    );
    notifyListeners();
  }

  /// Wendet Branding-Daten auf das aktuelle Theme an.
  void applyBranding(String? gymId, Branding? branding) {
    if (gymId == 'gym_01') {
      if (branding == null) {
        _applyMagentaDefaults();
        MagentaTones.normalizeFromGradient(AppGradients.brandGradient);
        _attachBrandTheme(
          focus: MagentaColors.focus,
          foreground: MagentaColors.textPrimary,
          useMagenta: true,
        );
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
      _currentTheme = AppTheme.customTheme(
        primary: primary,
        secondary: secondary,
      );
      AppGradients.setBrandGradient(gradStart, gradEnd);
      AppGradients.setCtaGlow(MagentaColors.focus);
      MagentaTones.normalizeFromGradient(AppGradients.brandGradient);
      _attachBrandTheme(
        focus: MagentaColors.focus,
        foreground: MagentaColors.textPrimary,
        useMagenta: true,
      );
      notifyListeners();
      return;
    }

    if (gymId == 'Club Aktiv') {
      if (branding == null) {
        _applyClubAktivDefaults();
        ClubAktivTones.normalizeFromGradient(AppGradients.brandGradient);
        _attachBrandTheme(
          focus: ClubAktivColors.focus,
          foreground: ClubAktivColors.textPrimary,
          useClubAktiv: true,
        );
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
      _currentTheme = AppTheme.customTheme(
        primary: primary,
        secondary: secondary,
      );
      AppGradients.setBrandGradient(gradStart, gradEnd);
      AppGradients.setCtaGlow(ClubAktivColors.focus);
      ClubAktivTones.normalizeFromGradient(AppGradients.brandGradient);
      _attachBrandTheme(
        focus: ClubAktivColors.focus,
        foreground: ClubAktivColors.textPrimary,
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
    _currentTheme = AppTheme.customTheme(primary: primary, secondary: accent);
    AppGradients.setBrandGradient(primary, accent);
    AppGradients.setCtaGlow(primary);
    _attachBrandTheme(
      focus: accent,
      foreground: AppColors.textPrimary,
    );
    notifyListeners();
  }

  void _applyMagentaDefaults() {
    _currentTheme = AppTheme.magentaDarkTheme;
    AppGradients.setBrandGradient(
      MagentaColors.primary500,
      MagentaColors.secondary,
    );
    AppGradients.setCtaGlow(MagentaColors.focus);
    MagentaTones.normalizeFromGradient(AppGradients.brandGradient);
    _attachBrandTheme(
      focus: MagentaColors.focus,
      foreground: MagentaColors.textPrimary,
      useMagenta: true,
    );
  }

  void _applyClubAktivDefaults() {
    _currentTheme = AppTheme.clubAktivDarkTheme;
    AppGradients.setBrandGradient(
      ClubAktivColors.primary500,
      ClubAktivColors.primary600,
    );
    AppGradients.setCtaGlow(ClubAktivColors.focus);
    ClubAktivTones.normalizeFromGradient(AppGradients.brandGradient);
    _attachBrandTheme(
      focus: ClubAktivColors.focus,
      foreground: ClubAktivColors.textPrimary,
      useClubAktiv: true,
    );
  }

  Color _parseHex(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  void _attachBrandTheme({
    required Color focus,
    required Color foreground,
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
                onBrand: foreground,
              );
    _currentTheme = _currentTheme.copyWith(extensions: [ext]);
  }
}

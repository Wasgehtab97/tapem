import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'design_tokens.dart';
import 'avatar_ring_theme.dart';

/// Provides the dark themes for the Tap’em app based on the new design tokens.
///
/// The themes defined here build upon `ThemeData.dark()` and override colours
/// and typography to create high-contrast, minimalistic UIs. Each theme
/// variant pairs different primary and secondary accents – e.g. mint +
/// turquoise – while maintaining a consistent base.
class AppTheme {
  static TextStyle _safeInter({
    required Color color,
    required double fontSize,
    FontWeight? fontWeight,
  }) {
    if (!GoogleFonts.config.allowRuntimeFetching) {
      return TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
        fontFamilyFallback: const ['Inter', 'sans-serif'],
      );
    }
    try {
      return GoogleFonts.inter(
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
      );
    } on Exception {
      return TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
        fontFamilyFallback: const ['Inter', 'sans-serif'],
      );
    }
  }

  /// Builds a ThemeData with the given primary and secondary colours.
  static ThemeData _buildTheme({
    required Color primary,
    required Color secondary,
    Color background = AppColors.background,
    Color surface = AppColors.surface,
    Color? surface2,
    Color textPrimary = AppColors.textPrimary,
    Color textSecondary = AppColors.textSecondary,
    Color focus = AppColors.accentTurquoise,
    Color? buttonColor,
  }) {
    final base = ThemeData(brightness: Brightness.dark);
    final scheme = ColorScheme.dark(
      primary: primary,
      secondary: secondary,
      background: background,
      surface: surface,
      onPrimary: textPrimary,
      onSurface: textSecondary,
      outline: focus,
    );
    final btnColor = buttonColor ?? secondary;
    final s2 = surface2 ?? surface;
    
    // CRITICAL: Always use consistent dark background like WorkoutDayScreen!
    // This creates a premium look where theme colors are only used for accents.
    const universalDarkBackground = Color(0xFF0A0A0A); // Very dark gray, almost black
    
    return base.copyWith(
      colorScheme: scheme,
      // ALWAYS dark background - theme colors only for accents!
      scaffoldBackgroundColor: universalDarkBackground,
      canvasColor: s2,
      cardColor: surface,
      hintColor: textSecondary,
      extensions: const <ThemeExtension<dynamic>>[
        AvatarRingTheme.fallback,
      ],
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        // AppBar also uses universal dark background!
        backgroundColor: universalDarkBackground,
        foregroundColor: textPrimary,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        // Bottom nav also uses universal dark background!
        backgroundColor: universalDarkBackground,
        selectedItemColor: secondary,
        unselectedItemColor: textSecondary,
        showUnselectedLabels: true,
      ),
      textTheme: TextTheme(
        // Large display numbers
        displayLarge: _safeInter(
          color: textPrimary,
          fontSize: AppFontSizes.kpi,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: _safeInter(
          color: textPrimary,
          fontSize: AppFontSizes.headline,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: _safeInter(
          color: textSecondary,
          fontSize: AppFontSizes.title,
        ),
        bodyMedium: _safeInter(
          color: textSecondary,
          fontSize: AppFontSizes.body,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: BorderSide(
            color: textSecondary.withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: BorderSide(color: focus),
        ),
        hintStyle: TextStyle(color: textSecondary.withOpacity(0.6)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: btnColor,
          foregroundColor: textPrimary,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: btnColor,
          side: BorderSide(color: btnColor.withOpacity(0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
        ),
      ),
    );
  }

  /// Builds a custom theme from arbitrary colors.
  static ThemeData customTheme({
    required Color primary,
    required Color secondary,
    Color? background,
    Color? surface,
    Color? surface2,
    Color? textPrimary,
    Color? textSecondary,
    Color? focus,
    Color? buttonColor,
  }) {
    return _buildTheme(
      primary: primary,
      secondary: secondary,
      background: background ?? AppColors.background,
      surface: surface ?? AppColors.surface,
      surface2: surface2,
      textPrimary: textPrimary ?? AppColors.textPrimary,
      textSecondary: textSecondary ?? AppColors.textSecondary,
      focus: focus ?? AppColors.accentTurquoise,
      buttonColor: buttonColor,
    );
  }

  /// The default dark theme using mint as primary and turquoise as secondary.
  static final ThemeData mintDarkTheme = _buildTheme(
    primary: AppColors.accentMint,
    secondary: AppColors.accentTurquoise,
    buttonColor: AppColors.accentTurquoise,
  );

  /// An alternate theme that highlights amber accents (e.g. for warning states).
  static final ThemeData amberDarkTheme = _buildTheme(
    primary: AppColors.accentAmber,
    secondary: AppColors.accentTurquoise,
    buttonColor: AppColors.accentTurquoise,
  );

  /// A neutral dark theme without strong branding accents.
  static final ThemeData neutralTheme = _buildTheme(
    primary: Colors.white,
    secondary: Colors.white,
    background: Colors.black,
    surface: Colors.black,
    textPrimary: Colors.white,
    textSecondary: Colors.white,
    focus: Colors.white,
    buttonColor: Colors.white,
  ).copyWith(
    scaffoldBackgroundColor: Colors.black,
    canvasColor: Colors.black,
    colorScheme: const ColorScheme.dark(
      primary: Colors.white,
      secondary: Colors.white,
      background: Colors.black,
      surface: Colors.black,
      onPrimary: Colors.black,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      onBackground: Colors.white,
      outline: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      centerTitle: true,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white70,
      indicatorColor: Colors.white,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.black,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white70,
      showUnselectedLabels: true,
    ),
    iconTheme: const IconThemeData(color: Colors.white),
    primaryIconTheme: const IconThemeData(color: Colors.white),
    cardTheme: const CardThemeData(
      color: Colors.black,
      surfaceTintColor: Colors.black,
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: Colors.black,
      surfaceTintColor: Colors.black,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      contentTextStyle: TextStyle(color: Colors.white),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.black,
      modalBackgroundColor: Colors.black,
      surfaceTintColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
      ),
    ),
    popupMenuTheme: const PopupMenuThemeData(
      color: Colors.black,
      textStyle: TextStyle(color: Colors.white),
    ),
    listTileTheme: const ListTileThemeData(
      textColor: Colors.white,
      iconColor: Colors.white,
      tileColor: Colors.black,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Colors.black,
      contentTextStyle: TextStyle(color: Colors.white),
      actionTextColor: Colors.white,
      behavior: SnackBarBehavior.floating,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    checkboxTheme: CheckboxThemeData(
      checkColor: MaterialStateProperty.all(Colors.black),
      fillColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.disabled)) {
          return Colors.white.withOpacity(0.3);
        }
        if (states.contains(MaterialState.selected)) {
          return Colors.white;
        }
        return Colors.transparent;
      }),
      side: const BorderSide(color: Colors.white, width: 1.5),
    ),
    radioTheme: RadioThemeData(
      fillColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.disabled)) {
          return Colors.white.withOpacity(0.3);
        }
        return Colors.white;
      }),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.disabled)) {
          return Colors.white54;
        }
        return Colors.white;
      }),
      trackColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.disabled)) {
          return Colors.white.withOpacity(0.2);
        }
        return Colors.white24;
      }),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        disabledBackgroundColor: Colors.black,
        disabledForegroundColor: Colors.white.withOpacity(0.4),
        overlayColor: Colors.white.withOpacity(0.1),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          side: const BorderSide(color: Colors.white, width: 2),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.white.withOpacity(0.4),
        overlayColor: Colors.white.withOpacity(0.1),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white, width: 2),
        disabledForegroundColor: Colors.white.withOpacity(0.4),
        overlayColor: Colors.white.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.black,
      labelStyle: const TextStyle(color: Colors.white),
      floatingLabelStyle: const TextStyle(color: Colors.white),
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
        borderSide: const BorderSide(color: Colors.white, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
        borderSide: const BorderSide(color: Colors.white, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
        borderSide: const BorderSide(color: Colors.white, width: 2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.4), width: 1.5),
      ),
    ),
    progressIndicatorTheme:
        const ProgressIndicatorThemeData(color: Colors.white),
    dividerColor: Colors.white24,
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: Colors.white,
      selectionColor: Colors.white24,
      selectionHandleColor: Colors.white,
    ),
  );

  /// Magenta dark theme for special gym branding.
  static final ThemeData magentaDarkTheme = _buildTheme(
    primary: MagentaColors.primary600,
    secondary: MagentaColors.secondary,
    background: MagentaColors.bg,
    surface: MagentaColors.surface1,
    surface2: MagentaColors.surface2,
    textPrimary: MagentaColors.textPrimary,
    textSecondary: MagentaColors.textSecondary,
    focus: MagentaColors.focus,
    buttonColor: MagentaColors.primary600,
  );

  /// Red/orange dark theme for the "Club Aktiv" gym.
  static final ThemeData clubAktivDarkTheme = _buildTheme(
    primary: ClubAktivColors.primary600,
    secondary: ClubAktivColors.secondary,
    background: ClubAktivColors.bg,
    surface: ClubAktivColors.surface1,
    surface2: ClubAktivColors.surface2,
    textPrimary: ClubAktivColors.textPrimary,
    textSecondary: ClubAktivColors.textSecondary,
    focus: ClubAktivColors.focus,
    buttonColor: ClubAktivColors.primary600,
  );
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthTheme {
  static const Color background = Color(0xFF070707);
  static const Color backgroundRaised = Color(0xFF0D0D0D);
  static const Color surface = Color(0xFF111111);
  static const Color surfaceRaised = Color(0xFF171717);
  static const Color surfacePressed = Color(0xFF222222);
  static const Color border = Color(0x26FFFFFF);
  static const Color borderStrong = Color(0x55FFFFFF);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xCCFFFFFF);
  static const Color textMuted = Color(0x99FFFFFF);
  static const Color actionPrimaryBackground = Colors.white;
  static const Color actionPrimaryForeground = Colors.black;
  static const Color danger = Color(0xFFFF8A80);
  static const double cardBorderRadius = 24.0;

  // --- Typography (Inter) ---
  static final TextStyle headingStyle = GoogleFonts.inter(
    fontSize: 30,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.3,
  );

  static final TextStyle subHeadingStyle = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static final TextStyle bodyStyle = GoogleFonts.inter(
    fontSize: 15,
    color: textSecondary,
    height: 1.5,
  );

  static final TextStyle labelStyle = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textMuted,
  );

  static final TextStyle buttonTextStyle = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: actionPrimaryForeground,
    letterSpacing: 0.2,
  );

  // --- Spacing ---
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;

  // --- Durations ---
  static const Duration animationDurationFast = Duration(milliseconds: 180);
  static const Duration animationDurationMedium = Duration(milliseconds: 320);
}

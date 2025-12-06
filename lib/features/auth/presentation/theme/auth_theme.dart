import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthTheme {
  // --- Gradients ---
  static const primaryGradient = LinearGradient(
    colors: [
      Color(0xFF8B5CF6), // Deep Purple
      Color(0xFF3B82F6), // Electric Blue
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const secondaryGradient = LinearGradient(
    colors: [
      Color(0xFFF472B6), // Coral Pink
      Color(0xFFE879F9), // Purple Pink
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const backgroundGradient = LinearGradient(
    colors: [
      Color(0xFF0F172A), // Slate 900
      Color(0xFF1E1B4B), // Indigo 950
      Color(0xFF000000), // Black
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // --- Glass Effects ---
  static final glassColor = Colors.white.withOpacity(0.08);
  static final glassBorderColor = Colors.white.withOpacity(0.15);
  static const double glassBlur = 10.0;
  static const double glassBorderRadius = 24.0;

  // --- Shadows ---
  static final softShadow = BoxShadow(
    color: Colors.black.withOpacity(0.2),
    blurRadius: 20,
    offset: const Offset(0, 10),
  );

  static final glowShadow = BoxShadow(
    color: const Color(0xFF8B5CF6).withOpacity(0.4),
    blurRadius: 15,
    spreadRadius: 1,
  );

  // --- Typography (Inter) ---
  static final TextStyle headingStyle = GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    letterSpacing: -0.5,
  );

  static final TextStyle subHeadingStyle = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: Colors.white.withOpacity(0.9),
  );

  static final TextStyle bodyStyle = GoogleFonts.inter(
    fontSize: 15,
    color: Colors.white.withOpacity(0.8),
    height: 1.5,
  );

  static final TextStyle labelStyle = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Colors.white.withOpacity(0.7),
  );

  static final TextStyle buttonTextStyle = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: 0.5,
  );

  // --- Spacing ---
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;

  // --- Durations ---
  static const Duration animationDurationFast = Duration(milliseconds: 200);
  static const Duration animationDurationMedium = Duration(milliseconds: 400);
}

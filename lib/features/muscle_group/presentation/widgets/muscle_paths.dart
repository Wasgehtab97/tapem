import 'package:flutter/widgets.dart';

/// Vector Path shapes for major front muscle groups used in the advanced heatmap.
class MusclePaths {
  /// Quadriceps (front thigh)
  static Path quadricepsPath(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(w * 0.35, h * 0.55)
      ..lineTo(w * 0.65, h * 0.55)
      ..lineTo(w * 0.60, h * 0.85)
      ..lineTo(w * 0.40, h * 0.85)
      ..close();
  }

  /// Vastus Medialis (inner knee)
  static Path vastusMedialisPath(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(w * 0.40, h * 0.83)
      ..quadraticBezierTo(w * 0.38, h * 0.88, w * 0.42, h * 0.90)
      ..quadraticBezierTo(w * 0.44, h * 0.88, w * 0.42, h * 0.83)
      ..close();
  }

  /// Tibialis Anterior (shin)
  static Path tibialisAnteriorPath(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(w * 0.45, h * 0.80)
      ..lineTo(w * 0.55, h * 0.80)
      ..lineTo(w * 0.53, h * 0.95)
      ..lineTo(w * 0.47, h * 0.95)
      ..close();
  }

  /// Gastrocnemius (calf)
  static Path gastrocnemiusPath(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(w * 0.38, h * 0.85)
      ..quadraticBezierTo(w * 0.30, h * 0.92, w * 0.35, h * 0.98)
      ..quadraticBezierTo(w * 0.40, h * 0.92, w * 0.38, h * 0.85)
      ..close();
  }

  /// Deltoid (shoulder)
  static Path deltoidPath(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(w * 0.25, h * 0.18)
      ..quadraticBezierTo(w * 0.20, h * 0.25, w * 0.28, h * 0.28)
      ..quadraticBezierTo(w * 0.33, h * 0.25, w * 0.30, h * 0.18)
      ..close();
  }

  /// Pectoralis Major (chest)
  static Path pectoralisPath(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(w * 0.30, h * 0.25)
      ..lineTo(w * 0.70, h * 0.25)
      ..lineTo(w * 0.65, h * 0.40)
      ..lineTo(w * 0.35, h * 0.40)
      ..close();
  }

  /// Rectus Abdominis (abs)
  static Path rectusAbdominisPath(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..addRect(Rect.fromLTWH(w * 0.42, h * 0.40, w * 0.16, h * 0.20));
  }

  /// Obliques (side abs)
  static Path obliquesPath(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(w * 0.25, h * 0.45)
      ..quadraticBezierTo(w * 0.20, h * 0.55, w * 0.25, h * 0.65)
      ..lineTo(w * 0.30, h * 0.60)
      ..quadraticBezierTo(w * 0.27, h * 0.55, w * 0.30, h * 0.50)
      ..close();
  }

  /// Biceps Brachii (upper arm front)
  static Path bicepsPath(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(w * 0.20, h * 0.40)
      ..quadraticBezierTo(w * 0.18, h * 0.50, w * 0.20, h * 0.60)
      ..lineTo(w * 0.25, h * 0.58)
      ..quadraticBezierTo(w * 0.23, h * 0.50, w * 0.25, h * 0.42)
      ..close();
  }

  /// Forearm Flexors (lower arm front)
  static Path forearmFlexorsPath(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(w * 0.20, h * 0.60)
      ..lineTo(w * 0.20, h * 0.80)
      ..lineTo(w * 0.28, h * 0.78)
      ..lineTo(w * 0.28, h * 0.58)
      ..close();
  }
}

/// Usage example:
/// canvas.drawPath(MusclePaths.quadricepsPath(size), paint);

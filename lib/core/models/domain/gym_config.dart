import 'dart:ui';

/// Domain‐Modell für das Gym-Branding.
/// Enthält alle Informationen, die zur
/// Laufzeit für Theme und Logo benötigt werden.
class GymConfig {
  /// Eindeutige Gym-ID (entspricht Firestore-Dokumenten-ID).
  final String id;

  /// Anzeigename des Gyms.
  final String displayName;

  /// Primärfarbe (für AppBar, Buttons o. Ä.).
  final Color primaryColor;

  /// Akzentfarbe (für Hervorhebungen).
  final Color accentColor;

  /// URL zum Gym-Logo (remote) oder lokaler Asset-Pfad als Fallback.
  final String logoUrl;

  /// Konstruktur.
  const GymConfig({
    required this.id,
    required this.displayName,
    required this.primaryColor,
    required this.accentColor,
    required this.logoUrl,
  });
}

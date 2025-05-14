import 'package:flutter/material.dart';

/// Konfiguration für ein Gym/Tenant, inkl. Theme-Einstellungen.
class GymConfig {
  /// Name des Gyms, wird als Anzeige-Name im Theme verwendet.
  final String displayName;

  /// Hauptfarbe der App (z. B. für AppBar).
  final Color primaryColor;

  /// Akzentfarbe der App (z. B. für Buttons).
  final Color accentColor;

  /// Logo-URL fürs Gym.
  final String logoUrl;

  const GymConfig({
    required this.displayName,
    required this.primaryColor,
    required this.accentColor,
    required this.logoUrl,
  });

  factory GymConfig.fromMap(Map<String, dynamic> map) {
    Color parseColor(dynamic v) {
      if (v is int) return Color(v);
      if (v is String) {
        final hex = v.replaceFirst('#', '');
        return Color(int.parse('0xFF$hex'));
      }
      throw ArgumentError('Ungültiger Farbwert: $v');
    }

    return GymConfig(
      displayName: map['display_name'] as String,
      primaryColor: parseColor(map['primary_color']),
      accentColor: parseColor(map['accent_color']),
      logoUrl: map['logo_url'] as String,
    );
  }

  Map<String, dynamic> toMap() => {
        'display_name': displayName,
        'primary_color': primaryColor.value,
        'accent_color': accentColor.value,
        'logo_url': logoUrl,
      };
}

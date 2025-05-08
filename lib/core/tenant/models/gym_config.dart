// lib/core/tenant/models/gym_config.dart

/// Enthält Branding- und Tenant-spezifische Einstellungen.
class GymConfig {
  final String gymId;
  final String name;
  final String primaryColorHex;
  // weitere Felder: logoUrl, secondaryColor, …

  GymConfig({
    required this.gymId,
    required this.name,
    required this.primaryColorHex,
  });

  factory GymConfig.fromMap(Map<String, dynamic> data) {
    return GymConfig(
      gymId: data['gymId'] as String,
      name: data['name'] as String,
      primaryColorHex: data['primaryColorHex'] as String,
    );
  }
}

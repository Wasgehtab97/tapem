import 'gym_config.dart';

/// Tenant-Kontext (ein Gym plus seine Config).
class Tenant {
  final String gymId;
  final GymConfig config;

  const Tenant({
    required this.gymId,
    required this.config,
  });

  /// Aus Firestore-Daten plus ID erzeugen.
  factory Tenant.fromMap(Map<String, dynamic> map, {required String id}) {
    return Tenant(
      gymId: id,
      config: GymConfig.fromMap(map['config'] as Map<String, dynamic>),
    );
  }
}

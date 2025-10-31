class MachineAttempt {
  final String id;
  final String gymId;
  final String machineId;
  final String userId;
  final String username;
  final double e1rm;
  final int? reps;
  final double? weight;
  final DateTime createdAt;
  final bool isMulti;
  final String? gender;
  final double? bodyWeightKg;

  const MachineAttempt({
    required this.id,
    required this.gymId,
    required this.machineId,
    required this.userId,
    required this.username,
    required this.e1rm,
    required this.createdAt,
    required this.isMulti,
    this.reps,
    this.weight,
    this.gender,
    this.bodyWeightKg,
  });
}

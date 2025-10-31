import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/machine_attempt.dart';

class MachineAttemptDto {
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

  const MachineAttemptDto({
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

  factory MachineAttemptDto.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    final timestamp = data['createdAt'];
    DateTime createdAt;
    if (timestamp is Timestamp) {
      createdAt = timestamp.toDate();
    } else {
      createdAt = DateTime.now();
    }
    return MachineAttemptDto(
      id: doc.id,
      gymId: data['gymId'] as String? ?? '',
      machineId: data['machineId'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      username: data['username'] as String? ?? '',
      e1rm: (data['e1rm'] as num?)?.toDouble() ?? 0,
      reps: (data['reps'] as num?)?.toInt(),
      weight: (data['weight'] as num?)?.toDouble(),
      createdAt: createdAt,
      isMulti: data['isMulti'] as bool? ?? false,
      gender: data['gender'] as String?,
      bodyWeightKg: (data['bodyWeightKg'] as num?)?.toDouble(),
    );
  }

  MachineAttempt toDomain() {
    return MachineAttempt(
      id: id,
      gymId: gymId,
      machineId: machineId,
      userId: userId,
      username: username,
      e1rm: e1rm,
      createdAt: createdAt,
      isMulti: isMulti,
      reps: reps,
      weight: weight,
      gender: gender,
      bodyWeightKg: bodyWeightKg,
    );
  }
}

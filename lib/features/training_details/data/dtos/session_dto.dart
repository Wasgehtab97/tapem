// lib/features/training_details/data/dtos/session_dto.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// Rohdaten eines einzelnen Log‐Eintrags aus Firestore.
class SessionDto {
  final String sessionId;
  final String deviceId;
  final String exerciseId;
  final DateTime timestamp;
  final double weight;
  final int reps;
  final double? dropWeightKg;
  final int? dropReps;
  final String note;
  final DocumentReference<Map<String, dynamic>> reference;

  SessionDto({
    required this.sessionId,
    required this.deviceId,
    required this.exerciseId,
    required this.timestamp,
    required this.weight,
    required this.reps,
    this.dropWeightKg,
    this.dropReps,
    required this.note,
    required this.reference,
  });

  factory SessionDto.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    // Erzeuge deviceId aus dem Pfad:
    final deviceRef = doc.reference.parent.parent;
    final deviceId = deviceRef?.id ?? '<unknown>';
    final exerciseId = data['exerciseId'] as String? ?? '';

    return SessionDto(
      sessionId: data['sessionId'] as String,
      deviceId: deviceId, // nicht mehr data['deviceId']
      exerciseId: exerciseId,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      weight: (data['weight'] as num).toDouble(),
      reps: (data['reps'] as num).toInt(),
      dropWeightKg: (data['dropWeightKg'] as num?)?.toDouble(),
      dropReps: (data['dropReps'] as num?)?.toInt(),
      note: data['note'] as String? ?? '',
      reference: doc.reference,
    );
  }
}

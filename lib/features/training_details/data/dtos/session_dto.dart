// lib/features/training_details/data/dtos/session_dto.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// Rohdaten eines einzelnen Log‐Eintrags aus Firestore.
class SessionDto {
  final String sessionId;
  final String deviceId;
  final String exerciseId;
  final String userId;
  final DateTime timestamp;
  final double weight;
  final int reps;
  final int setNumber;
  final double? dropWeightKg;
  final int? dropReps;
  final String note;
  final DocumentReference<Map<String, dynamic>> reference;

  SessionDto({
    required this.sessionId,
    required this.deviceId,
    required this.exerciseId,
    required this.userId,
    required this.timestamp,
    required this.weight,
    required this.reps,
    required this.setNumber,
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
    final userId = data['userId'] as String? ?? '';

    final rawNumber = data['setNumber'] ?? data['number'];
    int setNumber;
    if (rawNumber is num) {
      setNumber = rawNumber.toInt();
    } else if (rawNumber is String) {
      setNumber = int.tryParse(rawNumber) ?? 0;
    } else {
      setNumber = 0;
    }

    return SessionDto(
      sessionId: data['sessionId'] as String,
      deviceId: deviceId, // nicht mehr data['deviceId']
      exerciseId: exerciseId,
      userId: userId,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      weight: (data['weight'] as num).toDouble(),
      reps: (data['reps'] as num).toInt(),
      setNumber: setNumber,
      dropWeightKg: (data['dropWeightKg'] as num?)?.toDouble(),
      dropReps: (data['dropReps'] as num?)?.toInt(),
      note: data['note'] as String? ?? '',
      reference: doc.reference,
    );
  }
}

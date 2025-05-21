// lib/features/training_details/data/dtos/session_dto.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// Rohdaten eines einzelnen Log‐Eintrags aus Firestore.
class SessionDto {
  final String sessionId;
  final String deviceId;
  final DateTime timestamp;
  final int weight;
  final int reps;
  final String note;
  final DocumentReference<Map<String, dynamic>> reference;

  SessionDto({
    required this.sessionId,
    required this.deviceId,
    required this.timestamp,
    required this.weight,
    required this.reps,
    required this.note,
    required this.reference,
  });

  factory SessionDto.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    // Erzeuge deviceId aus dem Pfad:
    final deviceRef = doc.reference.parent.parent;
    final deviceId = deviceRef?.id ?? '<unknown>';

    return SessionDto(
      sessionId: data['sessionId'] as String,
      deviceId: deviceId, // nicht mehr data['deviceId']
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      weight: (data['weight'] as num).toInt(),
      reps: (data['reps'] as num).toInt(),
      note: data['note'] as String? ?? '',
      reference: doc.reference,
    );
  }
}

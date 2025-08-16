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
  final List<DropSetDto> dropSets;
  final String note;
  final DocumentReference<Map<String, dynamic>> reference;

  SessionDto({
    required this.sessionId,
    required this.deviceId,
    required this.exerciseId,
    required this.timestamp,
    required this.weight,
    required this.reps,
    this.dropSets = const [],
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
      dropSets: _readDropSets(data),
      note: data['note'] as String? ?? '',
      reference: doc.reference,
    );
  }

  static List<DropSetDto> _readDropSets(Map<String, dynamic> data) {
    final raw = data['dropSets'];
    if (raw is List) {
      return raw
          .map((e) => DropSetDto.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    final dw = (data['dropWeightKg'] as num?)?.toDouble();
    final dr = (data['dropReps'] as num?)?.toInt();
    if (dw != null && dr != null) {
      return [DropSetDto(weightKg: dw, reps: dr)];
    }
    return [];
  }
}

class DropSetDto {
  final double weightKg;
  final int reps;

  DropSetDto({required this.weightKg, required this.reps});

  factory DropSetDto.fromJson(Map<String, dynamic> json) => DropSetDto(
        weightKg: (json['weightKg'] as num).toDouble(),
        reps: (json['reps'] as num).toInt(),
      );

  Map<String, dynamic> toJson() => {'weightKg': weightKg, 'reps': reps};
}

// lib/features/gym/domain/models/gym_code.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a rotating gym access code with expiration
class GymCode {
  final String id;
  final String code;
  final String gymId;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isActive;
  final String createdBy;

  const GymCode({
    required this.id,
    required this.code,
    required this.gymId,
    required this.createdAt,
    required this.expiresAt,
    required this.isActive,
    required this.createdBy,
  });

  /// Check if this code is currently valid
  bool get isValid {
    final now = DateTime.now();
    return isActive && now.isBefore(expiresAt) && now.isAfter(createdAt);
  }

  /// Check if this code has expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Days until expiration (negative if expired)
  int get daysUntilExpiration {
    return expiresAt.difference(DateTime.now()).inDays;
  }

  factory GymCode.fromFirestore(String id, Map<String, dynamic> data) {
    return GymCode(
      id: id,
      code: data['code'] as String,
      gymId: data['gymId'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
      isActive: data['isActive'] as bool? ?? true,
      createdBy: data['createdBy'] as String? ?? 'unknown',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'code': code,
      'gymId': gymId,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'isActive': isActive,
      'createdBy': createdBy,
    };
  }

  GymCode copyWith({
    String? id,
    String? code,
    String? gymId,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool? isActive,
    String? createdBy,
  }) {
    return GymCode(
      id: id ?? this.id,
      code: code ?? this.code,
      gymId: gymId ?? this.gymId,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  @override
  String toString() {
    return 'GymCode(code: $code, gymId: $gymId, valid: $isValid, expires: $expiresAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GymCode && other.id == id && other.code == code;
  }

  @override
  int get hashCode => Object.hash(id, code);
}

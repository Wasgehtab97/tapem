// lib/features/gym/domain/models/gym_code_validation_result.dart

/// Result of gym code validation
class GymCodeValidationResult {
  final String gymId;
  final String gymName;
  final String code;
  final DateTime expiresAt;

  const GymCodeValidationResult({
    required this.gymId,
    required this.gymName,
    required this.code,
    required this.expiresAt,
  });

  /// Days until code expires
  int get daysUntilExpiration {
    return expiresAt.difference(DateTime.now()).inDays;
  }

  /// Check if code is expiring soon (within 7 days)
  bool get isExpiringSoon => daysUntilExpiration <= 7 && daysUntilExpiration > 0;

  @override
  String toString() {
    return 'GymCodeValidationResult(gymId: $gymId, gymName: $gymName, expiresAt: $expiresAt)';
  }
}

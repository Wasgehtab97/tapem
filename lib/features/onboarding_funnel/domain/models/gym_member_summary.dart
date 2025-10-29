import 'package:equatable/equatable.dart';

class GymMemberSummary extends Equatable {
  const GymMemberSummary({
    required this.userId,
    required this.memberNumber,
    this.createdAt,
  });

  final String userId;
  final String memberNumber;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [userId, memberNumber, createdAt];
}

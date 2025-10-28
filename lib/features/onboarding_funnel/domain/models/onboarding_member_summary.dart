import 'package:equatable/equatable.dart';

class OnboardingMemberSummary extends Equatable {
  final String userId;
  final String memberNumber;
  final String? displayName;
  final String? email;
  final DateTime? registeredAt;
  final DateTime? onboardingAssignedAt;
  final int trainingDays;

  const OnboardingMemberSummary({
    required this.userId,
    required this.memberNumber,
    this.displayName,
    this.email,
    this.registeredAt,
    this.onboardingAssignedAt,
    required this.trainingDays,
  });

  @override
  List<Object?> get props => [
        userId,
        memberNumber,
        displayName,
        email,
        registeredAt,
        onboardingAssignedAt,
        trainingDays,
      ];
}

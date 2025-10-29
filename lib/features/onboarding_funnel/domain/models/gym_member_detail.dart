import 'package:equatable/equatable.dart';

import 'gym_member_summary.dart';

class GymMemberDetail extends Equatable {
  const GymMemberDetail({
    required this.summary,
    this.displayName,
    this.email,
    this.userCreatedAt,
    required this.totalTrainingDays,
    required this.hasCompletedFirstScan,
  });

  final GymMemberSummary summary;
  final String? displayName;
  final String? email;
  final DateTime? userCreatedAt;
  final int totalTrainingDays;
  final bool hasCompletedFirstScan;

  String get memberNumber => summary.memberNumber;

  DateTime? get registeredAt => summary.createdAt;

  @override
  List<Object?> get props => [
        summary,
        displayName,
        email,
        userCreatedAt,
        totalTrainingDays,
        hasCompletedFirstScan,
      ];
}

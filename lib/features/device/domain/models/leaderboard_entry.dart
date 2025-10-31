import 'machine_attempt.dart';

enum LeaderboardScoreMode { absolute, relative }

enum LeaderboardGenderFilter { all, female, male }

class LeaderboardEntry {
  final MachineAttempt attempt;
  final double score;
  final LeaderboardScoreMode mode;

  const LeaderboardEntry({
    required this.attempt,
    required this.score,
    required this.mode,
  });

  bool get hasRelativeScore =>
      mode == LeaderboardScoreMode.relative && attempt.bodyWeightKg != null;

  double? get relativeValue =>
      attempt.bodyWeightKg != null && attempt.bodyWeightKg! > 0
          ? attempt.e1rm / attempt.bodyWeightKg!
          : null;
}

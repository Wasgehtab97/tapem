import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/features/device/domain/models/leaderboard_entry.dart';
import 'package:tapem/features/device/domain/models/machine_attempt.dart';
import 'package:tapem/features/device/domain/repositories/machine_attempt_repository.dart';
import 'package:tapem/features/device/domain/services/leaderboard_service.dart';
import 'package:tapem/features/device/domain/utils/leaderboard_time_utils.dart';
import 'package:tapem/features/device/presentation/widgets/machine_leaderboard_sheet.dart';
import 'package:tapem/l10n/app_localizations.dart';

class _NoopRepository implements MachineAttemptRepository {
  @override
  Future<List<MachineAttempt>> fetchTopAttempts({
    required String gymId,
    required String machineId,
    required range,
    LeaderboardGenderFilter genderFilter = LeaderboardGenderFilter.all,
    int limit = 3,
  }) async {
    return [];
  }
}

class _FakeLeaderboardService extends LeaderboardService {
  _FakeLeaderboardService({
    required this.absoluteEntries,
    required this.relativeEntries,
  }) : super(repository: _NoopRepository());

  final List<LeaderboardEntry> absoluteEntries;
  final List<LeaderboardEntry> relativeEntries;

  @override
  Future<List<LeaderboardEntry>> loadLeaderboard({
    required String gymId,
    required String machineId,
    required LeaderboardPeriod period,
    LeaderboardGenderFilter genderFilter = LeaderboardGenderFilter.all,
    LeaderboardScoreMode mode = LeaderboardScoreMode.absolute,
    int limit = 3,
  }) async {
    return mode == LeaderboardScoreMode.relative
        ? relativeEntries
        : absoluteEntries;
  }
}

LeaderboardEntry _buildEntry({
  required String id,
  required String username,
  required double e1rm,
  required double score,
  required LeaderboardScoreMode mode,
  int reps = 5,
  double weight = 100,
}) {
  final attempt = MachineAttempt(
    id: id,
    gymId: 'gym',
    machineId: 'machine',
    userId: 'user-$id',
    username: username,
    e1rm: e1rm,
    createdAt: DateTime(2024, 1, 10),
    isMulti: false,
    reps: reps,
    weight: weight,
    bodyWeightKg: 70,
  );
  return LeaderboardEntry(attempt: attempt, score: score, mode: mode);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MachineLeaderboardSheet', () {
    testWidgets('shows top entry for absolute mode', (tester) async {
      final service = _FakeLeaderboardService(
        absoluteEntries: [
          _buildEntry(
            id: '1',
            username: 'Alice',
            e1rm: 120,
            score: 120,
            mode: LeaderboardScoreMode.absolute,
          ),
          _buildEntry(
            id: '2',
            username: 'Bob',
            e1rm: 110,
            score: 110,
            mode: LeaderboardScoreMode.absolute,
          ),
        ],
        relativeEntries: [
          _buildEntry(
            id: '3',
            username: 'Charlie',
            e1rm: 100,
            score: 1.8,
            mode: LeaderboardScoreMode.relative,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: MachineLeaderboardSheet(
              gymId: 'gym',
              machineId: 'machine',
              isMulti: false,
              title: 'Machine',
              serviceOverride: service,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Alice'), findsOneWidget);
      expect(find.textContaining('120.0 kg'), findsOneWidget);
    });

    testWidgets('switches to relative leaderboard', (tester) async {
      final service = _FakeLeaderboardService(
        absoluteEntries: [
          _buildEntry(
            id: '1',
            username: 'Alice',
            e1rm: 120,
            score: 120,
            mode: LeaderboardScoreMode.absolute,
          ),
        ],
        relativeEntries: [
          _buildEntry(
            id: '2',
            username: 'Bob',
            e1rm: 105,
            score: 1.6,
            mode: LeaderboardScoreMode.relative,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: MachineLeaderboardSheet(
              gymId: 'gym',
              machineId: 'machine',
              isMulti: false,
              title: 'Machine',
              serviceOverride: service,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Alice'), findsOneWidget);

      await tester.tap(find.text('Relative'));
      await tester.pumpAndSettle();

      expect(find.text('Bob'), findsOneWidget);
    });
  });
}

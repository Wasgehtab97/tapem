import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/features/report/data/training_day_repository.dart';
import 'package:tapem/features/report/domain/gym_member.dart';
import 'package:tapem/features/report/presentation/screens/report_members_screen.dart';
import 'package:tapem/features/report/presentation/screens/report_members_usage_screen.dart';
import 'package:tapem/features/report/providers/report_providers.dart';
import 'package:tapem/l10n/app_localizations.dart';

class _FakeAuthProvider extends ChangeNotifier implements AuthProvider {
  _FakeAuthProvider({required String? userId}) : _userId = userId;

  final String? _userId;

  @override
  String? get userId => _userId;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeTrainingDayRepository extends TrainingDayRepository {
  _FakeTrainingDayRepository({required this.members, required this.counts})
    : super(firestore: FakeFirebaseFirestore());

  final List<GymMember> members;
  final Map<String, int> counts;

  @override
  Stream<List<GymMember>> watchGymMembers(String gymId) {
    return Stream<List<GymMember>>.value(members);
  }

  @override
  Future<Map<String, int>> fetchTrainingDayCounts(List<GymMember> members) {
    return Future<Map<String, int>>.value(<String, int>{
      for (final member in members) member.id: counts[member.id] ?? 0,
    });
  }
}

void main() {
  final members = <GymMember>[
    GymMember(id: 'u1', memberNumber: '0001', role: 'member', createdAt: null),
    GymMember(
      id: 'u2',
      memberNumber: '0002',
      role: 'gymowner',
      createdAt: null,
    ),
  ];

  testWidgets(
    'report members screen supports group actions for loaded members',
    (tester) async {
      final repo = _FakeTrainingDayRepository(
        members: members,
        counts: const <String, int>{'u1': 5, 'u2': 0},
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            trainingDayRepositoryProvider.overrideWithValue(repo),
            authControllerProvider.overrideWith(
              (ref) => _FakeAuthProvider(userId: ''),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const ReportMembersScreen(gymId: 'g1'),
          ),
        ),
      );

      await tester.pumpAndSettle();
      final loc = AppLocalizations.of(
        tester.element(find.byType(ReportMembersScreen)),
      )!;

      expect(find.text('0001'), findsOneWidget);
      expect(find.text('0002'), findsOneWidget);
      expect(find.byType(DataTable), findsNothing);

      await tester.tap(find.text(loc.reportMembersSegmentActions));
      await tester.pumpAndSettle();

      expect(find.text(loc.reportMembersSegmentCopy), findsOneWidget);
      expect(find.text(loc.reportMembersSegmentShare), findsOneWidget);
    },
  );

  testWidgets('report members usage screen renders usage buckets', (
    tester,
  ) async {
    final repo = _FakeTrainingDayRepository(
      members: members,
      counts: const <String, int>{'u1': 5, 'u2': 0},
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [trainingDayRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ReportMembersUsageScreen(gymId: 'g1'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('<1'), findsWidgets);
    expect(find.text('≥1'), findsWidgets);
    expect(find.text('>3'), findsWidgets);
  });
}

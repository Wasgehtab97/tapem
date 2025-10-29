import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tapem/features/onboarding_funnel/data/repositories/onboarding_funnel_repository.dart';
import 'package:tapem/features/onboarding_funnel/data/sources/firestore_onboarding_source.dart';
import 'package:tapem/features/onboarding_funnel/domain/models/gym_member_detail.dart';
import 'package:tapem/features/onboarding_funnel/domain/models/gym_member_summary.dart';
import 'package:tapem/features/onboarding_funnel/presentation/screens/onboarding_funnel_screen.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/l10n/app_localizations_en.dart';

void main() {
  group('OnboardingFunnelScreen', () {
    testWidgets('shows member count', (tester) async {
      final repository = _StubRepository(
        count: 12,
        onSearch: (_) async => null,
      );

      await tester.pumpWidget(
        _buildTestApp(
          OnboardingFunnelScreen(
            gymId: 'gymA',
            repository: repository,
            searchDebounce: Duration.zero,
          ),
        ),
      );

      await tester.pump();

      final loc = AppLocalizationsEn();
      expect(find.text(loc.onboardingFunnelCountLabel(12)), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
    });

    testWidgets('renders search result', (tester) async {
      final detail = GymMemberDetail(
        summary: GymMemberSummary(
          userId: 'user1',
          memberNumber: '0005',
          createdAt: DateTime(2024, 1, 2),
        ),
        displayName: 'Member',
        email: 'member@example.com',
        userCreatedAt: DateTime(2024, 1, 1),
        totalTrainingDays: 4,
        hasCompletedFirstScan: true,
      );
      final repository = _StubRepository(
        count: 5,
        onSearch: (_) async => detail,
      );

      await tester.pumpWidget(
        _buildTestApp(
          OnboardingFunnelScreen(
            gymId: 'gymA',
            repository: repository,
            searchDebounce: Duration.zero,
          ),
        ),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextField), '0005');
      await tester.pump();
      await tester.pump();

      final loc = AppLocalizationsEn();
      expect(find.text(loc.onboardingFunnelMemberNumberLabel('0005')), findsOneWidget);
      expect(find.text(loc.onboardingFunnelTrainingDays(4)), findsOneWidget);
    });

    testWidgets('shows empty state when search misses', (tester) async {
      final repository = _StubRepository(
        count: 2,
        onSearch: (_) async => null,
      );

      await tester.pumpWidget(
        _buildTestApp(
          OnboardingFunnelScreen(
            gymId: 'gymA',
            repository: repository,
            searchDebounce: Duration.zero,
          ),
        ),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextField), '0001');
      await tester.pump();
      await tester.pump();

      final loc = AppLocalizationsEn();
      expect(find.text(loc.onboardingFunnelSearchNoResult), findsOneWidget);
    });
  });
}

Widget _buildTestApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}

class _StubRepository extends OnboardingFunnelRepository {
  _StubRepository({
    required this.count,
    required this.onSearch,
  }) : super(source: _NoopSource());

  final int count;
  final Future<GymMemberDetail?> Function(String memberNumber) onSearch;

  @override
  Future<int> getMemberCount(String gymId) async => count;

  @override
  Future<GymMemberDetail?> findMemberByNumber(String gymId, String memberNumber) {
    return onSearch(memberNumber);
  }
}

class _NoopSource extends FirestoreOnboardingSource {
  _NoopSource() : super();
}

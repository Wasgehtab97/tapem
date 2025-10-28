import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:tapem/features/onboarding_funnel/data/onboarding_funnel_repository.dart';
import 'package:tapem/features/onboarding_funnel/domain/models/onboarding_member_summary.dart';
import 'package:tapem/features/onboarding_funnel/presentation/providers/onboarding_funnel_provider.dart';

class _MockOnboardingRepository extends Mock
    implements OnboardingFunnelRepository {}

void main() {
  group('OnboardingFunnelProvider', () {
    late _MockOnboardingRepository repository;
    late OnboardingFunnelProvider provider;

    setUp(() {
      repository = _MockOnboardingRepository();
      provider = OnboardingFunnelProvider(repository: repository);
    });

    test('loadMemberCount updates member count', () async {
      when(() => repository.getRegisteredMemberCount('gym1'))
          .thenAnswer((_) async => 7);

      await provider.loadMemberCount('gym1');

      expect(provider.memberCount, 7);
      expect(provider.countErrorMessage, isNull);
      expect(provider.isLoadingCount, isFalse);
    });

    test('searchMember populates searchResult on success', () async {
      final summary = OnboardingMemberSummary(
        userId: 'user1',
        memberNumber: '0003',
        displayName: 'Test User',
        email: 'test@example.com',
        registeredAt: DateTime(2024, 1, 1),
        onboardingAssignedAt: DateTime(2024, 1, 2),
        trainingDays: 2,
      );
      when(() => repository.getMemberByNumber('gym1', '0003'))
          .thenAnswer((_) async => summary);

      await provider.searchMember('gym1', '0003');

      expect(provider.searchResult, summary);
      expect(provider.searchErrorType, isNull);
      expect(provider.hasSearched, isTrue);
      expect(provider.isSearching, isFalse);
    });

    test('searchMember sets notFound when repository returns null', () async {
      when(() => repository.getMemberByNumber('gym1', '0008'))
          .thenAnswer((_) async => null);

      await provider.searchMember('gym1', '0008');

      expect(provider.searchResult, isNull);
      expect(provider.searchErrorType, OnboardingSearchErrorType.notFound);
      expect(provider.lastSearchNumber, '0008');
    });

    test('searchMember sets failure when repository throws', () async {
      when(() => repository.getMemberByNumber('gym1', '0009'))
          .thenThrow(Exception('network'));

      await provider.searchMember('gym1', '0009');

      expect(provider.searchErrorType, OnboardingSearchErrorType.failure);
      expect(provider.searchResult, isNull);
      expect(provider.isSearching, isFalse);
    });
  });
}

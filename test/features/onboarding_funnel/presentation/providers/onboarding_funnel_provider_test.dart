import 'package:flutter_test/flutter_test.dart';

import 'package:tapem/features/onboarding_funnel/data/repositories/onboarding_funnel_repository.dart';
import 'package:tapem/features/onboarding_funnel/data/sources/firestore_onboarding_source.dart';
import 'package:tapem/features/onboarding_funnel/domain/models/gym_member_detail.dart';
import 'package:tapem/features/onboarding_funnel/domain/models/gym_member_summary.dart';
import 'package:tapem/features/onboarding_funnel/presentation/providers/onboarding_funnel_provider.dart';

void main() {
  group('OnboardingFunnelProvider', () {
    test('loads member count once', () async {
      final repository = _FakeRepository(count: 12);
      final provider = OnboardingFunnelProvider(
        repository: repository,
        searchDebounce: Duration.zero,
      );

      await provider.loadMemberCount('gymA');

      expect(provider.memberCount, 12);
      expect(provider.isLoadingCount, isFalse);
    });

    test('loadMemberCount captures errors', () async {
      final provider = OnboardingFunnelProvider(
        repository: _FakeRepository(throwOnCount: true),
        searchDebounce: Duration.zero,
      );

      await provider.loadMemberCount('gymA');

      expect(provider.memberCount, isNull);
      expect(provider.errorMessage, isNotNull);
    });

    test('searchMember ignores incomplete input', () async {
      final repository = _FakeRepository(count: 1);
      final provider = OnboardingFunnelProvider(
        repository: repository,
        searchDebounce: Duration.zero,
      );

      provider.searchMember('gymA', '12');
      expect(provider.hasSearched, isFalse);
      expect(provider.selectedMember, isNull);
    });

    test('searchMember updates detail on success', () async {
      final detail = GymMemberDetail(
        summary: GymMemberSummary(
          userId: 'user1',
          memberNumber: '0005',
          createdAt: DateTime(2024, 1, 1),
        ),
        displayName: 'Member',
        email: 'member@example.com',
        userCreatedAt: DateTime(2024, 1, 1),
        totalTrainingDays: 3,
        hasCompletedFirstScan: true,
      );
      final repository = _FakeRepository(detail: detail);
      final provider = OnboardingFunnelProvider(
        repository: repository,
        searchDebounce: Duration.zero,
      );

      provider.searchMember('gymA', '0005');
      await Future<void>.delayed(Duration.zero);

      expect(provider.selectedMember, detail);
      expect(provider.hasSearched, isTrue);
      expect(provider.errorMessage, isNull);
    });

    test('searchMember sets error message on failure', () async {
      final repository = _FakeRepository(throwOnSearch: true);
      final provider = OnboardingFunnelProvider(
        repository: repository,
        searchDebounce: Duration.zero,
      );

      provider.searchMember('gymA', '0005');
      await Future<void>.delayed(Duration.zero);

      expect(provider.selectedMember, isNull);
      expect(provider.hasSearched, isTrue);
      expect(provider.errorMessage, isNotNull);
    });

    test('searchMember handles missing result', () async {
      final repository = _FakeRepository();
      final provider = OnboardingFunnelProvider(
        repository: repository,
        searchDebounce: Duration.zero,
      );

      provider.searchMember('gymA', '0005');
      await Future<void>.delayed(Duration.zero);

      expect(provider.selectedMember, isNull);
      expect(provider.hasSearched, isTrue);
      expect(provider.errorMessage, isNull);
    });
  });
}

class _FakeRepository extends OnboardingFunnelRepository {
  _FakeRepository({
    int count = 0,
    GymMemberDetail? detail,
    bool throwOnCount = false,
    bool throwOnSearch = false,
  })  : _count = count,
        _detail = detail,
        _throwOnCount = throwOnCount,
        _throwOnSearch = throwOnSearch,
        super(source: _NoopSource());

  final int _count;
  final GymMemberDetail? _detail;
  final bool _throwOnCount;
  final bool _throwOnSearch;

  @override
  Future<int> getMemberCount(String gymId) async {
    if (_throwOnCount) {
      throw OnboardingFunnelException('count error');
    }
    return _count;
  }

  @override
  Future<GymMemberDetail?> findMemberByNumber(String gymId, String memberNumber) async {
    if (_throwOnSearch) {
      throw OnboardingFunnelException('search error');
    }
    return _detail;
  }
}

class _NoopSource extends FirestoreOnboardingSource {
  _NoopSource() : super();
}

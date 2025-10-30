import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/repositories/onboarding_funnel_repository.dart';
import '../../domain/models/gym_member_detail.dart';
import '../../domain/utils/member_number_utils.dart';
import '../../utils/onboarding_funnel_logger.dart';

class OnboardingFunnelProvider extends ChangeNotifier {
  OnboardingFunnelProvider({
    required OnboardingFunnelRepository repository,
    Duration? searchDebounce,
  })  : _repository = repository,
        _searchDebounce = searchDebounce ?? const Duration(milliseconds: 350);

  final OnboardingFunnelRepository _repository;
  final Duration _searchDebounce;

  Timer? _searchTimer;
  bool _isLoadingCount = false;
  bool _isSearching = false;
  bool _hasSearched = false;
  int? _memberCount;
  GymMemberDetail? _selectedMember;
  String? _errorMessage;
  String? _pendingNormalizedQuery;
  String? _lastExecutedQuery;

  bool get isLoadingCount => _isLoadingCount;
  bool get isSearching => _isSearching;
  bool get hasSearched => _hasSearched;
  int? get memberCount => _memberCount;
  GymMemberDetail? get selectedMember => _selectedMember;
  String? get errorMessage => _errorMessage;

  Future<void> loadMemberCount(String gymId) async {
    if (_isLoadingCount || _memberCount != null) {
      return;
    }
    _isLoadingCount = true;
    _errorMessage = null;
    notifyListeners();
    try {
      logOnboardingFunnel(
        'provider:loadMemberCount:start',
        scope: 'OnboardingFunnel.Provider',
        data: {'gymId': gymId},
      );
      _memberCount = await _repository.getMemberCount(gymId);
      logOnboardingFunnel(
        'provider:loadMemberCount:success',
        scope: 'OnboardingFunnel.Provider',
        data: {'gymId': gymId, 'count': _memberCount},
      );
    } on OnboardingFunnelException catch (error) {
      _errorMessage = error.message;
      logOnboardingFunnel(
        'provider:loadMemberCount:error',
        scope: 'OnboardingFunnel.Provider',
        data: {'gymId': gymId},
        error: error,
      );
    } finally {
      _isLoadingCount = false;
      notifyListeners();
    }
  }

  void searchMember(String gymId, String query) {
    final normalized = normalizeMemberNumber(query);
    logOnboardingFunnel(
      'provider:searchMember:input',
      scope: 'OnboardingFunnel.Provider',
      data: {
        'gymId': gymId,
        'raw': query,
        'normalized': normalized,
      },
    );
    _searchTimer?.cancel();
    if (normalized == null) {
      _clearSearchState(reason: 'empty');
      return;
    }

    _pendingNormalizedQuery = normalized;

    if (_searchDebounce <= Duration.zero) {
      _performSearch(gymId, normalized, trigger: 'immediate');
      return;
    }

    _searchTimer = Timer(
      _searchDebounce,
      () {
        if (_pendingNormalizedQuery != normalized) {
          return;
        }
        _performSearch(gymId, normalized, trigger: 'debounced');
      },
    );
  }

  void submitSearch(String gymId, String query) {
    final normalized = normalizeMemberNumber(query) ?? _pendingNormalizedQuery;
    logOnboardingFunnel(
      'provider:searchMember:submit',
      scope: 'OnboardingFunnel.Provider',
      data: {
        'gymId': gymId,
        'raw': query,
        'normalized': normalized,
      },
    );
    _searchTimer?.cancel();
    if (normalized == null) {
      _clearSearchState(reason: 'submit-empty');
      return;
    }
    _pendingNormalizedQuery = normalized;
    _performSearch(gymId, normalized, trigger: 'submitted');
  }

  Future<void> _performSearch(
    String gymId,
    String normalizedQuery, {
    required String trigger,
  }) async {
    if (_lastExecutedQuery == normalizedQuery && trigger == 'debounced') {
      logOnboardingFunnel(
        'provider:searchMember:skip-duplicate',
        scope: 'OnboardingFunnel.Provider',
        data: {'gymId': gymId, 'normalized': normalizedQuery, 'trigger': trigger},
      );
      return;
    }
    _isSearching = true;
    _errorMessage = null;
    notifyListeners();
    try {
      logOnboardingFunnel(
        'provider:searchMember:start',
        scope: 'OnboardingFunnel.Provider',
        data: {
          'gymId': gymId,
          'normalized': normalizedQuery,
          'trigger': trigger,
        },
      );
      _selectedMember = await _repository.findMemberByNumber(gymId, normalizedQuery);
      _hasSearched = true;
      _lastExecutedQuery = normalizedQuery;
      logOnboardingFunnel(
        'provider:searchMember:success',
        scope: 'OnboardingFunnel.Provider',
        data: {
          'gymId': gymId,
          'normalized': normalizedQuery,
          'trigger': trigger,
          'found': _selectedMember != null,
        },
      );
    } on OnboardingFunnelException catch (error) {
      _errorMessage = error.message;
      _selectedMember = null;
      _hasSearched = true;
      _lastExecutedQuery = normalizedQuery;
      logOnboardingFunnel(
        'provider:searchMember:error',
        scope: 'OnboardingFunnel.Provider',
        data: {
          'gymId': gymId,
          'normalized': normalizedQuery,
          'trigger': trigger,
        },
        error: error,
      );
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  void _clearSearchState({required String reason}) {
    logOnboardingFunnel(
      'provider:searchMember:clear',
      scope: 'OnboardingFunnel.Provider',
      data: {'reason': reason},
    );
    _isSearching = false;
    _hasSearched = false;
    _selectedMember = null;
    _errorMessage = null;
    _pendingNormalizedQuery = null;
    _lastExecutedQuery = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    super.dispose();
  }
}

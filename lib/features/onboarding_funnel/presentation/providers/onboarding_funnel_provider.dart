import 'package:flutter/foundation.dart';

import '../../data/onboarding_funnel_repository.dart';
import '../../domain/models/onboarding_member_summary.dart';

enum OnboardingSearchErrorType { notFound, failure }

class OnboardingFunnelProvider extends ChangeNotifier {
  OnboardingFunnelProvider({OnboardingFunnelRepository? repository})
      : _repository = repository ?? OnboardingFunnelRepository();

  final OnboardingFunnelRepository _repository;

  bool _isLoadingCount = false;
  int? _memberCount;
  String? _countErrorMessage;
  String? _activeGymId;

  bool _isSearching = false;
  bool _hasSearched = false;
  String? _lastSearchNumber;
  OnboardingMemberSummary? _searchResult;
  OnboardingSearchErrorType? _searchErrorType;
  String? _searchErrorMessage;

  bool get isLoadingCount => _isLoadingCount;
  int? get memberCount => _memberCount;
  String? get countErrorMessage => _countErrorMessage;

  bool get isSearching => _isSearching;
  bool get hasSearched => _hasSearched;
  String? get lastSearchNumber => _lastSearchNumber;
  OnboardingMemberSummary? get searchResult => _searchResult;
  OnboardingSearchErrorType? get searchErrorType => _searchErrorType;
  String? get searchErrorMessage => _searchErrorMessage;

  Future<void> ensureInitialized(String gymId) async {
    if (_activeGymId != gymId || _memberCount == null) {
      await loadMemberCount(gymId);
    }
  }

  Future<void> loadMemberCount(String gymId) async {
    if (_isLoadingCount && _activeGymId == gymId) {
      return;
    }
    if (_activeGymId != gymId) {
      _resetForGym(gymId);
    }
    _isLoadingCount = true;
    _countErrorMessage = null;
    notifyListeners();

    try {
      final count = await _repository.getRegisteredMemberCount(gymId);
      _memberCount = count;
    } catch (error, stackTrace) {
      _countErrorMessage = error.toString();
      debugPrint('OnboardingFunnelProvider.loadMemberCount error: $error\n$stackTrace');
    } finally {
      _isLoadingCount = false;
      notifyListeners();
    }
  }

  Future<void> searchMember(String gymId, String memberNumber) async {
    if (_activeGymId != gymId) {
      _resetForGym(gymId);
    }

    _isSearching = true;
    _hasSearched = true;
    _lastSearchNumber = memberNumber;
    _searchResult = null;
    _searchErrorType = null;
    _searchErrorMessage = null;
    notifyListeners();

    try {
      final result =
          await _repository.getMemberByNumber(gymId, memberNumber);
      if (result == null) {
        _searchErrorType = OnboardingSearchErrorType.notFound;
      } else {
        _searchResult = result;
      }
    } catch (error, stackTrace) {
      _searchErrorType = OnboardingSearchErrorType.failure;
      _searchErrorMessage = error.toString();
      debugPrint('OnboardingFunnelProvider.searchMember error: $error\n$stackTrace');
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    _hasSearched = false;
    _lastSearchNumber = null;
    _searchResult = null;
    _searchErrorType = null;
    _searchErrorMessage = null;
    notifyListeners();
  }

  void _resetForGym(String gymId) {
    _activeGymId = gymId;
    _memberCount = null;
    _countErrorMessage = null;
    _hasSearched = false;
    _lastSearchNumber = null;
    _searchResult = null;
    _searchErrorType = null;
    _searchErrorMessage = null;
  }
}

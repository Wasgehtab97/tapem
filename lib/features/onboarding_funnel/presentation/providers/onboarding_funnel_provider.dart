import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../../data/repositories/onboarding_funnel_repository.dart';
import '../../domain/models/gym_member_detail.dart';
import '../../domain/utils/member_number_formatter.dart';

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
    developer.log(
      'Loading member count for gym=$gymId',
      name: 'OnboardingFunnelProvider',
    );
    try {
      _memberCount = await _repository.getMemberCount(gymId);
      developer.log(
        'Member count loaded: ${_memberCount ?? 'null'}',
        name: 'OnboardingFunnelProvider',
      );
    } on OnboardingFunnelException catch (error) {
      _errorMessage = error.message;
      developer.log(
        'Failed to load member count',
        name: 'OnboardingFunnelProvider',
        level: 1000,
        error: error,
      );
    } finally {
      _isLoadingCount = false;
      notifyListeners();
    }
  }

  void searchMember(String gymId, String query) {
    final digits = MemberNumberFormatter.digitsOnly(query);
    developer.log(
      'Received search query="$query" digits="$digits"',
      name: 'OnboardingFunnelProvider',
    );
    _searchTimer?.cancel();
    if (digits.length < 4) {
      _isSearching = false;
      _hasSearched = false;
      _errorMessage = null;
      _selectedMember = null;
      notifyListeners();
      developer.log(
        'Search query ignored - not enough digits',
        name: 'OnboardingFunnelProvider',
        level: 800,
      );
      return;
    }

    if (_searchDebounce <= Duration.zero) {
      _performSearch(gymId, digits);
      return;
    }

    _searchTimer = Timer(_searchDebounce, () => _performSearch(gymId, digits));
  }

  Future<void> _performSearch(String gymId, String query) async {
    _isSearching = true;
    _errorMessage = null;
    notifyListeners();
    final normalized = MemberNumberFormatter.normalize(query);
    developer.log(
      'Starting search for gym=$gymId number=$normalized',
      name: 'OnboardingFunnelProvider',
    );
    try {
      _selectedMember = await _repository.findMemberByNumber(gymId, normalized);
      _hasSearched = true;
      if (_selectedMember != null) {
        developer.log(
          'Search succeeded for number=$normalized userId=${_selectedMember!.summary.userId}',
          name: 'OnboardingFunnelProvider',
        );
      } else {
        developer.log(
          'Search completed - no member found for number=$normalized',
          name: 'OnboardingFunnelProvider',
          level: 800,
        );
      }
    } on OnboardingFunnelException catch (error) {
      _errorMessage = error.message;
      _selectedMember = null;
      _hasSearched = true;
      developer.log(
        'Search failed for number=$normalized',
        name: 'OnboardingFunnelProvider',
        level: 1000,
        error: error,
      );
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    super.dispose();
  }
}

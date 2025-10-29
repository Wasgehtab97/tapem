import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/repositories/onboarding_funnel_repository.dart';
import '../../domain/models/gym_member_detail.dart';

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
    try {
      _memberCount = await _repository.getMemberCount(gymId);
    } on OnboardingFunnelException catch (error) {
      _errorMessage = error.message;
    } finally {
      _isLoadingCount = false;
      notifyListeners();
    }
  }

  void searchMember(String gymId, String query) {
    final sanitized = query.trim();
    _searchTimer?.cancel();
    if (sanitized.length < 4) {
      _isSearching = false;
      _hasSearched = false;
      _errorMessage = null;
      _selectedMember = null;
      notifyListeners();
      return;
    }

    if (_searchDebounce <= Duration.zero) {
      _performSearch(gymId, sanitized);
      return;
    }

    _searchTimer = Timer(_searchDebounce, () => _performSearch(gymId, sanitized));
  }

  Future<void> _performSearch(String gymId, String query) async {
    _isSearching = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _selectedMember = await _repository.findMemberByNumber(gymId, query);
      _hasSearched = true;
    } on OnboardingFunnelException catch (error) {
      _errorMessage = error.message;
      _selectedMember = null;
      _hasSearched = true;
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

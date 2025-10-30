import 'dart:async';
import 'dart:developer' as developer;

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
    developer.log(
      'Loading member count for gymId=$gymId',
      name: _logTag,
    );
    try {
      _memberCount = await _repository.getMemberCount(gymId);
      developer.log(
        'Successfully loaded member count: $_memberCount',
        name: _logTag,
      );
    } on OnboardingFunnelException catch (error) {
      _errorMessage = error.message;
      developer.log(
        'Failed to load member count: ${error.message}',
        name: _logTag,
        error: error,
      );
    } finally {
      _isLoadingCount = false;
      notifyListeners();
    }
  }

  void searchMember(String gymId, String query) {
    final sanitized = query.trim();
    developer.log(
      'Received search input="$query" sanitized="$sanitized"',
      name: _logTag,
    );
    _searchTimer?.cancel();
    if (sanitized.length < 4) {
      _isSearching = false;
      _hasSearched = false;
      _errorMessage = null;
      _selectedMember = null;
      notifyListeners();
      developer.log(
        'Search input too short (<4). Resetting state.',
        name: _logTag,
      );
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
    developer.log(
      'Performing search for member="$query" in gymId=$gymId',
      name: _logTag,
    );
    try {
      _selectedMember = await _repository.findMemberByNumber(gymId, query);
      _hasSearched = true;
      if (_selectedMember == null) {
        developer.log(
          'Search completed with no result for member="$query"',
          name: _logTag,
        );
      } else {
        developer.log(
          'Search successful for member="$query" -> userId=${_selectedMember!.summary.userId}',
          name: _logTag,
        );
      }
    } on OnboardingFunnelException catch (error) {
      _errorMessage = error.message;
      _selectedMember = null;
      _hasSearched = true;
      developer.log(
        'Search failed for member="$query": ${error.message}',
        name: _logTag,
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

  static const String _logTag = 'OnboardingFunnelProvider';
}

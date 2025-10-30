import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';

import '../../domain/models/gym_member_detail.dart';
import '../sources/firestore_onboarding_source.dart';

class OnboardingFunnelException implements Exception {
  OnboardingFunnelException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => 'OnboardingFunnelException: $message';
}

class OnboardingFunnelRepository {
  OnboardingFunnelRepository({FirestoreOnboardingSource? source})
      : _source = source ?? FirestoreOnboardingSource();

  final FirestoreOnboardingSource _source;

  Future<int> getMemberCount(String gymId) async {
    developer.log(
      'Requesting member count for gymId=$gymId',
      name: _logTag,
    );
    try {
      final count = await _source.countMembers(gymId);
      developer.log(
        'Member count loaded: $count',
        name: _logTag,
      );
      return count;
    } on FirebaseException catch (error) {
      developer.log(
        'Firebase error while loading member count',
        name: _logTag,
        error: error,
      );
      throw OnboardingFunnelException('Failed to load member count', error);
    } catch (error) {
      developer.log(
        'Unknown error while loading member count',
        name: _logTag,
        error: error,
      );
      throw OnboardingFunnelException('Failed to load member count', error);
    }
  }

  Future<GymMemberDetail?> findMemberByNumber(
    String gymId,
    String memberNumber,
  ) async {
    developer.log(
      'Searching for memberNumber=$memberNumber in gymId=$gymId',
      name: _logTag,
    );
    try {
      final detail = await _source.fetchMemberDetail(gymId, memberNumber);
      developer.log(
        detail == null
            ? 'MemberNumber=$memberNumber not found'
            : 'MemberNumber=$memberNumber resolved to userId=${detail.summary.userId}',
        name: _logTag,
      );
      return detail;
    } on FirebaseException catch (error) {
      developer.log(
        'Firebase error while searching for memberNumber=$memberNumber',
        name: _logTag,
        error: error,
      );
      throw OnboardingFunnelException('Failed to load member detail', error);
    } catch (error) {
      developer.log(
        'Unknown error while searching for memberNumber=$memberNumber',
        name: _logTag,
        error: error,
      );
      throw OnboardingFunnelException('Failed to load member detail', error);
    }
  }

  static const String _logTag = 'OnboardingFunnelRepository';
}

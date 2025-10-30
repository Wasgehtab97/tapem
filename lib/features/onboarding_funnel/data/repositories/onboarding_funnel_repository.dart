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
    try {
      developer.log(
        'Repository: loading member count for gym=$gymId',
        name: 'OnboardingFunnelRepository',
      );
      return await _source.countMembers(gymId);
    } on FirebaseException catch (error) {
      throw OnboardingFunnelException('Failed to load member count', error);
    } catch (error) {
      throw OnboardingFunnelException('Failed to load member count', error);
    }
  }

  Future<GymMemberDetail?> findMemberByNumber(
    String gymId,
    String memberNumber,
  ) async {
    try {
      developer.log(
        'Repository: searching for member gym=$gymId number=$memberNumber',
        name: 'OnboardingFunnelRepository',
      );
      return await _source.fetchMemberDetail(gymId, memberNumber);
    } on FirebaseException catch (error) {
      throw OnboardingFunnelException('Failed to load member detail', error);
    } catch (error) {
      throw OnboardingFunnelException('Failed to load member detail', error);
    }
  }
}

import 'package:firebase_core/firebase_core.dart';

import '../../domain/models/gym_member_detail.dart';
import '../../domain/utils/member_number_utils.dart';
import '../sources/firestore_onboarding_source.dart';
import '../../utils/onboarding_funnel_logger.dart';

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
      logOnboardingFunnel(
        'getMemberCount:start',
        scope: 'OnboardingFunnel.Repository',
        data: {'gymId': gymId},
      );
      final count = await _source.countMembers(gymId);
      logOnboardingFunnel(
        'getMemberCount:success',
        scope: 'OnboardingFunnel.Repository',
        data: {'gymId': gymId, 'count': count},
      );
      return count;
    } on FirebaseException catch (error, stack) {
      logOnboardingFunnel(
        'getMemberCount:error',
        scope: 'OnboardingFunnel.Repository',
        data: {'gymId': gymId},
        error: error,
        stackTrace: stack,
      );
      throw OnboardingFunnelException('Failed to load member count', error);
    } catch (error, stack) {
      logOnboardingFunnel(
        'getMemberCount:error',
        scope: 'OnboardingFunnel.Repository',
        data: {'gymId': gymId},
        error: error,
        stackTrace: stack,
      );
      throw OnboardingFunnelException('Failed to load member count', error);
    }
  }

  Future<GymMemberDetail?> findMemberByNumber(
    String gymId,
    String memberNumber,
  ) async {
    try {
      final normalized = normalizeMemberNumber(memberNumber);
      if (normalized == null) {
        logOnboardingFunnel(
          'findMemberByNumber:skip-empty',
          scope: 'OnboardingFunnel.Repository',
          data: {'gymId': gymId, 'input': memberNumber},
        );
        return null;
      }
      logOnboardingFunnel(
        'findMemberByNumber:start',
        scope: 'OnboardingFunnel.Repository',
        data: {'gymId': gymId, 'normalized': normalized},
      );
      final detail = await _source.fetchMemberDetail(gymId, normalized);
      logOnboardingFunnel(
        'findMemberByNumber:success',
        scope: 'OnboardingFunnel.Repository',
        data: {
          'gymId': gymId,
          'normalized': normalized,
          'found': detail != null,
        },
      );
      return detail;
    } on FirebaseException catch (error, stack) {
      logOnboardingFunnel(
        'findMemberByNumber:error',
        scope: 'OnboardingFunnel.Repository',
        data: {'gymId': gymId, 'input': memberNumber},
        error: error,
        stackTrace: stack,
      );
      throw OnboardingFunnelException('Failed to load member detail', error);
    } catch (error, stack) {
      logOnboardingFunnel(
        'findMemberByNumber:error',
        scope: 'OnboardingFunnel.Repository',
        data: {'gymId': gymId, 'input': memberNumber},
        error: error,
        stackTrace: stack,
      );
      throw OnboardingFunnelException('Failed to load member detail', error);
    }
  }
}

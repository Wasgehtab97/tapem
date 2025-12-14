import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/features/coaching/data/sources/firestore_coach_invite_source.dart';
import 'package:tapem/features/coaching/domain/models/coach_invite.dart';

final coachInviteSourceProvider = Provider<FirestoreCoachInviteSource>((ref) {
  return FirestoreCoachInviteSource();
});

final clientCoachInvitesProvider =
    FutureProvider<List<CoachInvite>>((ref) async {
  final authState = ref.watch(authViewStateProvider);
  final userId = authState.userId;
  if (userId == null) {
    return [];
  }
  final source = ref.watch(coachInviteSourceProvider);
  return source.getInvitesForClient(clientId: userId);
});

/// Pending-Einladungen für die E-Mail des aktuellen Users (Coach-Sicht).
final pendingInvitesForCoachEmailProvider =
    FutureProvider<List<CoachInvite>>((ref) async {
  final auth = ref.watch(authControllerProvider);
  final email = auth.userEmail;
  if (email == null || email.isEmpty) {
    return [];
  }
  final source = ref.watch(coachInviteSourceProvider);
  return source.getPendingInvitesForEmail(email: email);
});

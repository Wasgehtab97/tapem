import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tapem/core/observability/owner_action_observability_service.dart';
import 'package:tapem/features/friends/domain/models/public_profile.dart';

class GymMemberDirectoryService {
  GymMemberDirectoryService({
    FirebaseFirestore? firestore,
    OwnerActionObservabilityService? observability,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _observability =
           observability ?? OwnerActionObservabilityService.instance;

  final FirebaseFirestore _firestore;
  final OwnerActionObservabilityService _observability;

  Stream<List<PublicProfile>> watchProfilesForGym(String gymId) {
    return _firestore
        .collection('users')
        .where('gymCodes', arrayContains: gymId)
        .snapshots()
        .map((snapshot) {
          final profiles = snapshot.docs
              .map((doc) => PublicProfile.fromMap(doc.id, doc.data()))
              .toList(growable: false);
          final sorted = profiles.toList(growable: true)
            ..sort((a, b) => a.safeLower.compareTo(b.safeLower));
          return sorted;
        });
  }

  Stream<String> watchDisplayName(String uid, {String fallback = ''}) {
    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      final data = snapshot.data();
      final username = (data?['username'] as String? ?? '').trim();
      if (username.isNotEmpty) {
        return username;
      }
      return fallback.isNotEmpty ? fallback : uid;
    });
  }

  Future<int> backfillUsernameLower(
    String gymId, {
    Duration throttle = const Duration(milliseconds: 50),
  }) async {
    return _observability.trackAction(
      action: 'owner.symbols.backfill_username_lower',
      command: () async {
        final query = await _firestore
            .collection('users')
            .where('gymCodes', arrayContains: gymId)
            .where('usernameLower', isNull: true)
            .get();
        var updated = 0;
        for (final doc in query.docs) {
          final data = doc.data();
          final name = (data['username'] as String? ?? '').trim();
          await doc.reference.update({'usernameLower': name.toLowerCase()});
          updated += 1;
          if (throttle > Duration.zero) {
            await Future<void>.delayed(throttle);
          }
        }
        return updated;
      },
    );
  }
}

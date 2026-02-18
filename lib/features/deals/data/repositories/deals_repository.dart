import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:tapem/features/deals/domain/models/deal.dart';

class DealsRepository {
  final FirebaseFirestore _firestore;

  DealsRepository(this._firestore);

  /// Liefert aktive Deals mit robuster Auth-Refresh-Logik.
  ///
  /// Falls während des Listens ein `permission-denied` auftritt (z. B. weil
  /// das Firebase-Token abgelaufen ist), wird das Token erneuert und der
  /// Stream still neu abonniert, ohne die UI in einen Fehlerzustand zu
  /// schicken.
  Stream<List<Deal>> getDealsStream() async* {
    var refreshedAfterDenied = false;
    while (true) {
      try {
        await for (final snapshot
            in _firestore
                .collection('deals')
                .where('isActive', isEqualTo: true)
                .orderBy('priority')
                .snapshots()) {
          debugPrint('📦 Deals Snapshot: ${snapshot.docs.length} docs found');
          yield snapshot.docs
              .map((doc) => Deal.fromMap(doc.id, doc.data()))
              .toList();
        }
        // Normal stream end (unlikely) – break out
        break;
      } on FirebaseException catch (e) {
        debugPrint('🔴 Deals Stream Error: $e');
        if (e.code == 'permission-denied') {
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) {
            debugPrint('ℹ️ Deals: user signed out, stopping stream.');
            yield const <Deal>[];
            return;
          }
          if (!refreshedAfterDenied) {
            try {
              await user.getIdToken(true);
              refreshedAfterDenied = true;
              debugPrint('🔄 Deals: token refreshed after permission-denied');
              continue; // re-subscribe loop
            } catch (_) {
              // fall through to stop to avoid infinite loops
            }
          }
          debugPrint('⛔️ Deals: permission denied persists, stopping stream.');
          yield const <Deal>[];
          return;
        }
        rethrow;
      }
    }
  }

  /// Liefert ALLE Deals (auch inaktive) für Administrationszwecke.
  Stream<List<Deal>> getAllDealsStream() {
    return _firestore
        .collection('deals')
        .snapshots()
        .map((snapshot) {
          debugPrint(
            '📦 Admin Deals Snapshot: ${snapshot.docs.length} docs found',
          );
          return snapshot.docs
              .map((doc) => Deal.fromMap(doc.id, doc.data()))
              .toList();
        })
        .handleError((error) {
          debugPrint('🔴 Admin Deals Stream Error: $error');
          throw error;
        });
  }

  Future<void> saveDeal(Deal deal) async {
    final data = deal.toMap();
    data['updatedAt'] = FieldValue.serverTimestamp();

    if (deal.id.isEmpty) {
      data['createdAt'] = FieldValue.serverTimestamp();
      debugPrint('📝 Deals: Creating new deal: $data');
      await _firestore.collection('deals').add(data);
    } else {
      debugPrint('📝 Deals: Updating deal ${deal.id}: $data');
      await _firestore
          .collection('deals')
          .doc(deal.id)
          .set(data, SetOptions(merge: true));
    }
  }

  Future<void> deleteDeal(String dealId) async {
    await _firestore.collection('deals').doc(dealId).delete();
  }

  Future<void> trackClick(String dealId) async {
    try {
      final docRef = _firestore.collection('deals').doc(dealId);
      await docRef.update({'clickCount': FieldValue.increment(1)});
    } catch (e) {
      // Ignore errors (like permission denied) for non-admins to prevent UI impact
      debugPrint('⚠️ Silent failure tracking deal click: $e');
    }
  }
}

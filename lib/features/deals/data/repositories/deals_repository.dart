import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:tapem/features/deals/domain/models/deal.dart';

class DealsRepository {
  final FirebaseFirestore _firestore;

  DealsRepository(this._firestore);

  Stream<List<Deal>> getDealsStream() {
    return _firestore
        .collection('deals')
        .where('isActive', isEqualTo: true)
        .orderBy('priority')
        .snapshots()
        .map((snapshot) {
      debugPrint('📦 Deals Snapshot: ${snapshot.docs.length} docs found');
      return snapshot.docs.map((doc) {
        return Deal.fromMap(doc.id, doc.data());
      }).toList();
    }).handleError((error) {
      debugPrint('🔴 Deals Stream Error: $error');
      throw error;
    });
  }

  Future<void> trackClick(String dealId) async {
    try {
      final docRef = _firestore.collection('deals').doc(dealId);
      await docRef.update({
        'clickCount': FieldValue.increment(1),
      });
    } catch (e) {
      // Ignore errors (like permission denied) for non-admins to prevent UI impact
      debugPrint('⚠️ Silent failure tracking deal click: $e');
    }
  }
}

// lib/data/sources/affiliate/firestore_affiliate_source.dart

import 'package:cloud_firestore/cloud_firestore.dart';


class FirestoreAffiliateSource {
  final FirebaseFirestore _fs;
  FirestoreAffiliateSource({FirebaseFirestore? firestore})
      : _fs = firestore ?? FirebaseFirestore.instance;

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> fetchOffers() =>
      _fs.collection('affiliateOffers').get().then((snap) => snap.docs);

  Future<void> trackClick(String offerId) =>
      _fs.collection('affiliateClicks').add({
        'offerId': offerId,
        'clicked_at': FieldValue.serverTimestamp(),
      });
}

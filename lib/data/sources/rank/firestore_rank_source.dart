// lib/data/sources/rank/firestore_rank_source.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tapem/domain/models/user_data.dart';

/// Firestore-Source für Ranglisten-Daten.
class FirestoreRankSource {
  final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection('ranks');

  Future<List<UserData>> fetchAllUsers() async {
    final snap = await _col.get();
    return snap.docs.map((doc) {
      final d = doc.data();
      return UserData(
        id: doc.id,
        displayName: d['displayName'] as String,
        email: d['email'] as String,
        joinedAt: (d['joinedAt'] as Timestamp).toDate(),
        totalExperience: d['totalExperience'] as int,
        currentStreak: d['currentStreak'] as int,
      );
    }).toList();
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

int nextMemberNumber(Map<String, dynamic>? gymData, {String? gymId}) {
  final raw = gymData?['memberNumberCounter'];
  final current = raw is int
      ? raw
      : raw is num
          ? raw.toInt()
          : 0;
  final next = current + 1;
  if (next > 9999) {
    final id = gymId ?? 'unknown';
    throw StateError('Maximum member number reached for gym $id');
  }
  return next;
}

String formatMemberNumber(int value) => value.toString().padLeft(4, '0');

void updateMemberNumberCounter(Transaction tx, DocumentReference<Map<String, dynamic>> gymRef, int value) {
  tx.set(gymRef, {'memberNumberCounter': value}, SetOptions(merge: true));
}

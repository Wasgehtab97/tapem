import 'package:cloud_firestore/cloud_firestore.dart';

class AvatarOwned {
  AvatarOwned({
    required this.id,
    required this.source,
    this.unlockedAt,
    this.reason,
    this.by,
    this.grantHash,
  });

  final String id;
  final String source; // "gym:{gymId}" | "global"
  final DateTime? unlockedAt;
  final String? reason;
  final String? by; // "system" or admin uid
  final String? grantHash;

  factory AvatarOwned.fromMap(String id, Map<String, dynamic> data) {
    return AvatarOwned(
      id: id,
      source: data['source'] as String? ?? 'global',
      unlockedAt: (data['unlockedAt'] as Timestamp?)?.toDate(),
      reason: data['reason'] as String?,
      by: data['by'] as String?,
      grantHash: data['grantHash'] as String?,
    );
  }
}

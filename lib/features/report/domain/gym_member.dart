import 'package:cloud_firestore/cloud_firestore.dart';

class GymMember {
  GymMember({
    required this.id,
    required this.memberNumber,
    required this.role,
    required this.createdAt,
  });

  final String id;
  final String memberNumber;
  final String? role;
  final DateTime? createdAt;

  static GymMember? fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    if (data == null) {
      return null;
    }

    final memberNumber = (data['memberNumber'] as String? ?? '').trim();
    final role = data['role'] as String?;
    final createdAt = _parseDateTime(data['createdAt']);

    return GymMember(
      id: snapshot.id,
      memberNumber: memberNumber,
      role: role,
      createdAt: createdAt,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}

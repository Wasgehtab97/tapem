// lib/features/rank/data/device_xp.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// Modell für Erfahrungspunkte an einem Gerät
class DeviceXp {
  final int xp;
  final DateTime? updatedAt;

  DeviceXp({required this.xp, this.updatedAt});

  factory DeviceXp.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return DeviceXp(
      xp: data['xp'] as int? ?? 0,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() => {
        'xp': xp,
        if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      };
}

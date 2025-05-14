// lib/data/sources/report/firestore_report_source.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tapem/domain/models/device_info.dart';
import 'package:tapem/domain/models/report_entry.dart';

/// Firestore-Source für Report-Daten.
class FirestoreReportSource {
  final FirebaseFirestore _fs;
  FirestoreReportSource({FirebaseFirestore? firestore})
      : _fs = firestore ?? FirebaseFirestore.instance;

  /// Holt alle Geräte fürs Reporting (DeviceInfo).
  Future<List<DeviceInfo>> fetchDevices(String gymId) async {
    final snap = await _fs
        .collection('gyms')
        .doc(gymId)
        .collection('devices')
        .get();
    return snap.docs
        .map((doc) => DeviceInfo.fromMap(doc.data(), id: doc.id))
        .toList();
  }

  /// Holt das Feedback-Status-Mapping pro Device.
  Future<Map<String, String>> fetchFeedbackStatus(String gymId) async {
    final snap = await _fs
        .collection('gyms')
        .doc(gymId)
        .collection('feedback_status')
        .get();
    return {
      for (var doc in snap.docs) doc.id: doc.data()['status'] as String,
    };
  }

  /// Holt die Report-Daten (Sessions & Volumen).
  Future<List<ReportEntry>> fetchReportData({
    required String gymId,
    String? deviceId,
    DateTime? start,
    DateTime? end,
  }) async {
    Query<Map<String, dynamic>> query = _fs
        .collection('gyms')
        .doc(gymId)
        .collection('reports');

    if (deviceId != null) query = query.where('device_id', isEqualTo: deviceId);
    if (start != null) query = query.where('date', isGreaterThanOrEqualTo: start);
    if (end != null) query = query.where('date', isLessThanOrEqualTo: end);

    final snap = await query.get();
    return snap.docs
        .map((doc) => ReportEntry.fromMap(doc.data(), id: doc.id))
        .toList();
  }
}

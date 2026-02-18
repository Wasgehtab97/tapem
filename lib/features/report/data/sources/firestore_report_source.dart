// lib/features/report/data/sources/firestore_report_source.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tapem/features/report/domain/models/report_daily_aggregate.dart';

class FirestoreReportSource {
  final FirebaseFirestore _fs;
  FirestoreReportSource([FirebaseFirestore? fs])
    : _fs = fs ?? FirebaseFirestore.instance;

  /// Alle Geräte des Gyms laden
  Future<List<DocumentSnapshot<Map<String, dynamic>>>> fetchDevices(
    String gymId,
  ) {
    return _fs
        .collection('gyms')
        .doc(gymId)
        .collection('devices')
        .get()
        .then((snap) => snap.docs);
  }

  /// Für ein Gerät alle Log-Dokumente laden
  Future<List<DocumentSnapshot<Map<String, dynamic>>>> fetchLogsForDevice(
    String gymId,
    String deviceId, {
    DateTime? since,
  }) {
    Query<Map<String, dynamic>> query = _fs
        .collection('gyms')
        .doc(gymId)
        .collection('devices')
        .doc(deviceId)
        .collection('logs');

    if (since != null) {
      query = query
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
          .orderBy('timestamp', descending: true);
    }

    return query.get().then((snap) => snap.docs);
  }

  Future<List<ReportDailyAggregate>> fetchDailyAggregates(
    String gymId, {
    DateTime? since,
  }) async {
    Query<Map<String, dynamic>> query = _fs
        .collection('gyms')
        .doc(gymId)
        .collection('reportDaily')
        .orderBy('dayKey');
    if (since != null) {
      query = query.where(
        'dayKey',
        isGreaterThanOrEqualTo: _dayKeyFromDate(since),
      );
    }
    final snap = await query.get();
    return snap.docs
        .map((doc) => ReportDailyAggregate.fromMap(doc.id, doc.data()))
        .toList(growable: false);
  }

  static String _dayKeyFromDate(DateTime date) {
    final utc = date.toUtc();
    final month = utc.month.toString().padLeft(2, '0');
    final day = utc.day.toString().padLeft(2, '0');
    return '${utc.year}$month$day';
  }
}

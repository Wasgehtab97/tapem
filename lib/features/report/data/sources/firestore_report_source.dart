// lib/features/report/data/sources/firestore_report_source.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreReportSource {
  final FirebaseFirestore _fs;
  FirestoreReportSource([FirebaseFirestore? fs]) 
      : _fs = fs ?? FirebaseFirestore.instance;

  /// Alle Geräte des Gyms laden
  Future<List<DocumentSnapshot<Map<String,dynamic>>>> fetchDevices(String gymId) {
    return _fs
      .collection('gyms')
      .doc(gymId)
      .collection('devices')
      .get()
      .then((snap) => snap.docs);
  }

  /// Für ein Gerät alle Log-Dokumente laden
  Future<List<DocumentSnapshot<Map<String,dynamic>>>> fetchLogsForDevice(
      String gymId, String deviceId) {
    return _fs
      .collection('gyms')
      .doc(gymId)
      .collection('devices')
      .doc(deviceId)
      .collection('logs')
      .get()
      .then((snap) => snap.docs);
  }
}

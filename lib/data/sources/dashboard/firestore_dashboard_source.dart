// lib/data/sources/dashboard/firestore_dashboard_source.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tapem/domain/models/dashboard_data.dart';
import 'package:tapem/domain/models/device_info.dart';
import 'package:tapem/domain/models/exercise_entry.dart';

/// Firestore-Source für Dashboard-Daten.
class FirestoreDashboardSource {
  final FirebaseFirestore _fs;
  FirestoreDashboardSource({FirebaseFirestore? firestore})
      : _fs = firestore ?? FirebaseFirestore.instance;

  /// Lädt Gerätedaten und Übungen aus Firestore.
  Future<DashboardData> loadDevice(
    String deviceId, {
    String? secretCode,
  }) async {
    final doc = await _fs.collection('devices').doc(deviceId).get();
    final deviceInfo = DeviceInfo.fromMap(doc.data()!, id: doc.id);

    // Übungen aus Subcollection "entries"
    final snap = await _fs
        .collection('devices')
        .doc(deviceId)
        .collection('entries')
        .orderBy('timestamp', descending: false)
        .get();

    final entries = snap.docs.map((d) {
      final data = d.data();
      return ExerciseEntry.fromMap(
        data,
        id: d.id,
      );
    }).toList();

    return DashboardData(device: deviceInfo, entries: entries);
  }

  Future<void> addSet({
    required String deviceId,
    required String exercise,
    required int sets,
    required double weight,
    required int reps,
  }) {
    return _fs
        .collection('devices')
        .doc(deviceId)
        .collection('entries')
        .add({
      'device_id': deviceId,
      'device_name': exercise,
      'exercise': exercise,
      'training_date': FieldValue.serverTimestamp(),
      'timestamp': FieldValue.serverTimestamp(),
      'sets': sets,
      'weight': weight,
      'reps': reps,
    });
  }

  Future<void> finishSession({
    required String deviceId,
    required String exercise,
  }) {
    return _fs
        .collection('devices')
        .doc(deviceId)
        .collection('sessions')
        .add({
      'exercise': exercise,
      'ended_at': FieldValue.serverTimestamp(),
    });
  }
}

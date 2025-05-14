import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tapem/domain/models/device_model.dart';

/// Firestore-Quelle für Geräte.
class FirestoreDeviceSource {
  final FirebaseFirestore _db;
  FirestoreDeviceSource([FirebaseFirestore? firestore])
      : _db = firestore ?? FirebaseFirestore.instance;

  Future<String> createDevice({
    required String name,
    required String exerciseMode,
  }) async {
    final doc = await _db.collection('devices').add({
      'name': name,
      'exercise_mode': exerciseMode,
      'secret_code': '', // initial leer oder generiert
    });
    return doc.id;
  }

  Future<void> updateDevice({
    required String documentId,
    required String name,
    required String exerciseMode,
    required String secretCode,
  }) {
    return _db.collection('devices').doc(documentId).update({
      'name': name,
      'exercise_mode': exerciseMode,
      'secret_code': secretCode,
    });
  }

  Future<List<DeviceModel>> getAllDevices() async {
    final snap = await _db.collection('devices').get();
    return snap.docs
        .map((d) => DeviceModel.fromMap(d.data(), documentId: d.id))
        .toList();
  }
}

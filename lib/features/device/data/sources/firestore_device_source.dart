// lib/features/device/data/sources/firestore_device_source.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/device.dart';
import '../dtos/device_dto.dart';

class FirestoreDeviceSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<DeviceDto>> getDevicesForGym(String gymId) async {
    final snap = await _firestore
      .collection('gyms').doc(gymId)
      .collection('devices')
      .orderBy('id')
      .get();
    return snap.docs.map((doc) => DeviceDto.fromDocument(doc)).toList();
  }

  Future<void> createDevice(String gymId, Device device) {
    return _firestore
      .collection('gyms').doc(gymId)
      .collection('devices').doc(device.uid)
      .set(device.toJson());
  }

  // Neu: Gerät löschen
  Future<void> deleteDevice(String gymId, String deviceId) {
    return _firestore
      .collection('gyms').doc(gymId)
      .collection('devices').doc(deviceId)
      .delete();
  }
}

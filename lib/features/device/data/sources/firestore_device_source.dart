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
      .orderBy('name')
      .get();
    return snap.docs
      .map((doc) => DeviceDto.fromDocument(doc))
      .toList();
  }

  /// Accepts your domain-level Device model and writes it to Firestore
  Future<void> createDevice(String gymId, Device device) {
    return _firestore
      .collection('gyms').doc(gymId)
      .collection('devices').doc(device.id)
      .set(device.toJson());
  }
}

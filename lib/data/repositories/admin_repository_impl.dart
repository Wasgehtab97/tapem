import 'package:tapem/domain/models/device_model.dart';
import 'package:tapem/domain/repositories/admin_repository.dart';
import 'package:tapem/data/sources/admin/firestore_admin_source.dart';

class AdminRepositoryImpl implements AdminRepository {
  final FirestoreAdminSource _source;
  AdminRepositoryImpl({FirestoreAdminSource? source})
      : _source = source ?? FirestoreAdminSource();

  @override
  Future<List<DeviceModel>> fetchDevices() async {
    final docs = await _source.fetchDevices();
    return docs.map((doc) {
      return DeviceModel.fromMap(
        doc.data(),
        documentId: doc.id,
      );
    }).toList();
  }

  @override
  Future<String> createDevice({
    required String name,
    required String exerciseMode,
  }) =>
      _source.createDevice(
        name: name,
        exerciseMode: exerciseMode,
      );

  @override
  Future<void> updateDevice({
    required String documentId,
    required String name,
    required String exerciseMode,
    required String secretCode,
  }) =>
      _source.updateDevice(
        documentId: documentId,
        name: name,
        exerciseMode: exerciseMode,
        secretCode: secretCode,
      );
}

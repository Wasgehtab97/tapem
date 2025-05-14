import 'package:tapem/domain/models/device_model.dart';
import 'package:tapem/domain/repositories/gym_repository.dart';
import 'package:tapem/data/sources/gym/firestore_gym_source.dart';


class GymRepositoryImpl implements GymRepository {
  final FirestoreGymSource _source;
  GymRepositoryImpl({FirestoreGymSource? source})
      : _source = source ?? FirestoreGymSource();

  @override
  Future<List<DeviceModel>> fetchDevices({String? nameQuery}) async {
    final docs = await _source.fetchDevices(nameQuery: nameQuery);
    return docs.map((doc) {
      return DeviceModel.fromMap(
        doc.data(),
        documentId: doc.id,
      );
    }).toList();
  }
}

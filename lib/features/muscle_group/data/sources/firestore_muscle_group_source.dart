import 'package:cloud_firestore/cloud_firestore.dart';

import '../dtos/muscle_group_dto.dart';
import '../../domain/models/muscle_group.dart';

class FirestoreMuscleGroupSource {
  final FirebaseFirestore _firestore;

  FirestoreMuscleGroupSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String gymId) {
    return _firestore.collection('gyms').doc(gymId).collection('muscleGroups');
  }

  Future<List<MuscleGroupDto>> getMuscleGroups(String gymId) async {
    final snap = await _col(gymId).get();
    return snap.docs.map(MuscleGroupDto.fromDocument).toList();
  }

  Future<void> saveMuscleGroup(String gymId, MuscleGroup group) {
    final dto = MuscleGroupDto.fromModel(group);
    return _col(gymId).doc(dto.id).set(dto.toJson());
  }

  Future<void> deleteMuscleGroup(String gymId, String groupId) {
    return _col(gymId).doc(groupId).delete();
  }
}

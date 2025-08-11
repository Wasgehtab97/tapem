import 'package:cloud_firestore/cloud_firestore.dart';

import '../dtos/muscle_group_dto.dart';
import '../../domain/models/muscle_group.dart';

class FirestoreMuscleGroupSource {
  final FirebaseFirestore _firestore;

  FirestoreMuscleGroupSource([FirebaseFirestore? firestore])
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

  Future<String> ensureRegionGroup(String gymId, MuscleRegion region) async {
    final snap =
        await _col(gymId).where('region', isEqualTo: region.name).get();
    if (snap.docs.isNotEmpty) {
      final canonical = _canonicalName(region);
      for (final doc in snap.docs) {
        final name = (doc.data()['name'] as String? ?? '').toLowerCase();
        if (name == canonical) return doc.id;
      }
      return snap.docs.first.id;
    }
    final ref = _col(gymId).doc();
    final dto = MuscleGroupDto(name: _canonicalLabel(region), region: region)
      ..id = ref.id;
    await ref.set(dto.toJson());
    return ref.id;
  }

  String _canonicalName(MuscleRegion region) => region.name.toLowerCase();

  String _canonicalLabel(MuscleRegion region) {
    switch (region) {
      case MuscleRegion.chest:
        return 'chest';
      case MuscleRegion.back:
        return 'back';
      case MuscleRegion.shoulders:
        return 'shoulders';
      case MuscleRegion.arms:
        return 'arms';
      case MuscleRegion.core:
        return 'core';
      case MuscleRegion.legs:
        return 'legs';
    }
  }
}

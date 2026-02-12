import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/features/manufacturer/data/repositories/manufacturer_repository_impl.dart';
import 'package:tapem/features/manufacturer/domain/models/manufacturer.dart';
import 'package:tapem/features/manufacturer/domain/repositories/manufacturer_repository.dart';
import 'package:tapem/core/providers/auth_providers.dart';

// Repository Provider
final manufacturerRepositoryProvider = Provider<ManufacturerRepository>((ref) {
  return ManufacturerRepositoryImpl(FirebaseFirestore.instance);
});

// Use Cases Providers (simplified as Repository methods for now)

/// Fetches global manufacturers
final globalManufacturersProvider = FutureProvider<List<Manufacturer>>((ref) async {
  final repo = ref.watch(manufacturerRepositoryProvider);
  return repo.getGlobalManufacturers();
});

/// Fetches manufacturers for the current active gym
final gymManufacturersProvider = FutureProvider.autoDispose<List<Manufacturer>>((ref) async {
  final repo = ref.watch(manufacturerRepositoryProvider);
  final gymId = ref.watch(authControllerProvider).gymCode;
  
  if (gymId == null) {
    return const [];
  }
  
  return repo.getGymManufacturers(gymId);
});

final seedGlobalManufacturersProvider = Provider<Future<void> Function()>((ref) {
  final repo = ref.watch(manufacturerRepositoryProvider);
  return repo.seedGlobalManufacturers;
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/gym_repository_impl.dart';
import '../data/sources/firestore_gym_source.dart';
import '../domain/models/gym_config.dart';
import '../domain/usecases/get_gym_by_id.dart';
import '../domain/usecases/list_gyms.dart';

final gymRepositoryProvider = Provider<GymRepositoryImpl>((ref) {
  return GymRepositoryImpl(FirestoreGymSource());
});

final listGymsProvider = FutureProvider<List<GymConfig>>((ref) async {
  final repo = ref.watch(gymRepositoryProvider);
  return ListGyms(repo).execute();
});

final gymByIdProvider =
    FutureProvider.family<GymConfig, String>((ref, gymId) async {
  final repo = ref.watch(gymRepositoryProvider);
  return GetGymById(repo).execute(gymId);
});

final gymSearchQueryProvider = StateProvider<String>((ref) => '');

final filteredGymsProvider = Provider<List<GymConfig>>((ref) {
  final gyms = ref.watch(listGymsProvider).maybeWhen(
        data: (data) => data,
        orElse: () => const <GymConfig>[],
      );
  final query = ref.watch(gymSearchQueryProvider).trim().toLowerCase();
  if (query.length < 3) {
    return const <GymConfig>[];
  }
  return gyms
      .where((gym) =>
          gym.name.toLowerCase().startsWith(query))
      .toList();
});

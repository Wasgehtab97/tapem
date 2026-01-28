import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/features/deals/data/repositories/deals_repository.dart';
import 'package:tapem/features/deals/domain/models/deal.dart';

final dealsRepositoryProvider = Provider<DealsRepository>((ref) {
  return DealsRepository(FirebaseFirestore.instance);
});

final dealsStreamProvider = StreamProvider<List<Deal>>((ref) {
  final repository = ref.watch(dealsRepositoryProvider);
  return repository.getDealsStream();
});

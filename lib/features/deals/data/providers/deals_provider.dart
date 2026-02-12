import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/features/deals/data/repositories/deals_repository.dart';
import 'package:tapem/features/deals/domain/models/deal.dart';

final dealsRepositoryProvider = Provider<DealsRepository>((ref) {
  return DealsRepository(FirebaseFirestore.instance);
});

final dealsStreamProvider = StreamProvider<List<Deal>>((ref) {
  final auth = ref.watch(authViewStateProvider);
  if (!auth.isLoggedIn) {
    return Stream.value(const <Deal>[]);
  }
  final repository = ref.watch(dealsRepositoryProvider);
  return repository.getDealsStream();
});

final allDealsStreamProvider = StreamProvider<List<Deal>>((ref) {
  final auth = ref.watch(authViewStateProvider);
  if (!auth.isLoggedIn) {
    return Stream.value(const <Deal>[]);
  }
  final repository = ref.watch(dealsRepositoryProvider);
  return repository.getAllDealsStream();
});

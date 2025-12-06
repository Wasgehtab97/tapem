import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/firebase_provider.dart';
import '../data/sticker_repository.dart';
import '../domain/models/sticker.dart';

/// Provider for StickerRepository
final stickerRepositoryProvider = Provider<StickerRepository>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return StickerRepository(firestore: firestore);
});

/// Provider for available stickers
final availableStickersProvider = FutureProvider<List<Sticker>>((ref) {
  final repository = ref.watch(stickerRepositoryProvider);
  return repository.getAvailableStickers();
});

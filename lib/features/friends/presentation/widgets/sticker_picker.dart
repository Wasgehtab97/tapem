import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/sticker.dart';
import '../../providers/sticker_provider.dart';

class StickerPicker extends ConsumerWidget {
  const StickerPicker({
    required this.onStickerSelected,
    super.key,
  });

  final void Function(Sticker sticker) onStickerSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stickersAsync = ref.watch(availableStickersProvider);

    return Container(
      height: 250,
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Stickers',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          Expanded(
            child: stickersAsync.when(
              data: (stickers) {
                return GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: stickers.length,
                  itemBuilder: (context, index) {
                    final sticker = stickers[index];
                    return InkWell(
                      onTap: () => onStickerSelected(sticker),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: sticker.imageUrl.startsWith('asset://')
                            ? Image.asset(
                                sticker.imageUrl.substring(8), // Remove 'asset://' prefix
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.error_outline);
                                },
                              )
                            : Image.network(
                                sticker.imageUrl,
                                fit: BoxFit.contain,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.error_outline);
                                },
                              ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Error loading stickers: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

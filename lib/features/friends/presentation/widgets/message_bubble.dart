import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../domain/models/chat_message.dart';
import '../../providers/sticker_provider.dart';

/// Displays a single message bubble in the chat.
///
/// Shows sent messages on the right (blue) and received messages on the left (grey).
class MessageBubble extends ConsumerWidget {
  const MessageBubble({
    required this.message,
    this.isRead = false,
    super.key,
  });

  final ChatMessage message;
  final bool isRead;

  bool get _isMe => message.senderId == FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final timeFormat = DateFormat('HH:mm');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            _isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            decoration: BoxDecoration(
              color: message.type == MessageType.sticker
                  ? Colors.transparent
                  : (_isMe
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHighest),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: _isMe ? const Radius.circular(16) : Radius.zero,
                bottomRight: _isMe ? Radius.zero : const Radius.circular(16),
              ),
            ),
            padding: message.type == MessageType.sticker
                ? EdgeInsets.zero
                : const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Message content
                if (message.type == MessageType.text && message.text != null)
                  Text(
                    message.text!,
                    style: TextStyle(
                      color: _isMe
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                      fontSize: 16,
                    ),
                  )
                else if (message.type == MessageType.sticker &&
                    message.stickerId != null)
                  FutureBuilder(
                    future: ref
                        .read(stickerRepositoryProvider)
                        .getStickerById(message.stickerId!),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data != null) {
                        final imageUrl = snapshot.data!.imageUrl;
                        
                        // Check if it's a local asset (starts with asset://)
                        if (imageUrl.startsWith('asset://')) {
                          final assetPath = imageUrl.substring(8); // Remove 'asset://' prefix
                          return Image.asset(
                            assetPath,
                            width: 120,
                            height: 120,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stack) =>
                                const Icon(Icons.broken_image, size: 48),
                          );
                        }
                        
                        // Otherwise, load from network
                        return Image.network(
                          imageUrl,
                          width: 120,
                          height: 120,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return SizedBox(
                              width: 120,
                              height: 120,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stack) =>
                              const Icon(Icons.broken_image, size: 48),
                        );
                      }
                      return const SizedBox(width: 120, height: 120);
                    },
                  ),

                // Future: Highlight message content would go here

                const SizedBox(height: 4),

                // Timestamp and Read Receipt
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (message.nonce != null) ...[
                      Icon(
                        Icons.lock,
                        size: 12,
                        color: message.type == MessageType.sticker
                            ? theme.colorScheme.onSurface.withOpacity(0.6)
                            : (_isMe
                                ? theme.colorScheme.onPrimary.withOpacity(0.7)
                                : theme.colorScheme.onSurface.withOpacity(0.6)),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      timeFormat.format(message.createdAt),
                      style: TextStyle(
                        color: message.type == MessageType.sticker
                            ? theme.colorScheme.onSurface.withOpacity(0.6)
                            : (_isMe
                                ? theme.colorScheme.onPrimary.withOpacity(0.7)
                                : theme.colorScheme.onSurface.withOpacity(0.6)),
                        fontSize: 12,
                      ),
                    ),
                    if (_isMe) ...[
                      const SizedBox(width: 4),
                      Icon(
                        isRead ? Icons.done_all : Icons.check,
                        size: 16,
                        color: message.type == MessageType.sticker
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onPrimary.withOpacity(0.7),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

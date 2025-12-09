import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/auth_providers.dart';
import '../../domain/models/chat_message.dart';
import '../../providers/chat_providers.dart';
import '../../providers/chat_unread_provider.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input.dart';
import '../widgets/sticker_picker.dart';
import '../../domain/models/sticker.dart';

/// Screen for chatting with a friend.
///
/// Displays messages in real-time and allows sending new messages.
class FriendChatScreen extends ConsumerStatefulWidget {
  const FriendChatScreen({
    required this.friendUid,
    required this.friendName,
    super.key,
  });

  final String friendUid;
  final String friendName;

  @override
  ConsumerState<FriendChatScreen> createState() => _FriendChatScreenState();
}

class _FriendChatScreenState extends ConsumerState<FriendChatScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;
  bool _showStickerPicker = false;

  @override
  void initState() {
    super.initState();
    // Mark conversation as read when opening chat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markConversationAsRead();
    });
  }

  Future<void> _markConversationAsRead() async {
    try {
      final repository = ref.read(chatRepositoryProvider);
      final auth = ref.read(authViewStateProvider);
      final currentUserId = auth.userId;

      if (currentUserId == null) return;

      final conversationId =
          repository.getConversationId(currentUserId, widget.friendUid);

      await repository.markAsRead(
        currentUserId: currentUserId,
        conversationId: conversationId,
      );

      // Update local unread state immediately for responsive badge behaviour.
      ref
          .read(chatUnreadProvider.notifier)
          .markFriendAsRead(widget.friendUid);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FriendChatScreen] markAsRead failed: $e');
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleSendMessage(String text) async {
    if (_isSending) return;

    setState(() => _isSending = true);

    try {
      final service = ref.read(chatServiceProvider);
      await service.sendTextMessage(
        friendUid: widget.friendUid,
        text: text,
      );

      // Scroll to bottom after sending
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Senden: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _handleStickerPressed() {
    setState(() {
      _showStickerPicker = !_showStickerPicker;
    });
    // Scroll to bottom when opening picker
    if (_showStickerPicker) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _handleStickerSelected(Sticker sticker) async {
    // Close picker after selection (optional, maybe keep open for multiple?)
    // setState(() => _showStickerPicker = false);

    try {
      final service = ref.read(chatServiceProvider);
      await service.sendStickerMessage(
        friendUid: widget.friendUid,
        stickerId: sticker.id,
      );

      // Scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Senden des Stickers: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessagesProvider(widget.friendUid));
    final conversationAsync = ref.watch(chatConversationProvider(widget.friendUid));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.friendName),
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'Noch keine Nachrichten\nSchreib die erste Nachricht!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                // Get friend's last read timestamp
                final conversation = conversationAsync.valueOrNull;
                final friendLastReadAt = conversation?.lastReadAt?[widget.friendUid];

                // Always keep the view scrolled to the latest message
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(
                      _scrollController.position.maxScrollExtent,
                    );
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    
                    // Check if message is read by friend
                    // Message is read if it's created before or at friend's lastReadAt
                    final isRead = friendLastReadAt != null &&
                        !message.createdAt.isAfter(friendLastReadAt);

                    return MessageBubble(
                      message: message,
                      isRead: isRead,
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text(
                  'Fehler beim Laden der Nachrichten:\n$error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          ),

          // Message input
          MessageInput(
            onSend: _handleSendMessage,
            onStickerPressed: _handleStickerPressed,
            enabled: !_isSending,
          ),

          // Sticker Picker
          if (_showStickerPicker)
            StickerPicker(
              onStickerSelected: _handleStickerSelected,
            ),
        ],
      ),
    );
  }
}

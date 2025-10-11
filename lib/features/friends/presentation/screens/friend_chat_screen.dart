import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:tapem/core/providers/auth_provider.dart';
import '../../data/friend_chat_api.dart';
import '../../data/friend_chat_source.dart';
import '../../domain/models/friend_message.dart';
import '../../providers/friend_chat_summary_provider.dart';
import 'package:tapem/l10n/app_localizations.dart';

class FriendChatScreen extends StatefulWidget {
  const FriendChatScreen({super.key, required this.friendUid, required this.friendName});

  final String friendUid;
  final String friendName;

  static Route<void> route({required String friendUid, required String friendName}) {
    return MaterialPageRoute(
      builder: (_) => FriendChatScreen(friendUid: friendUid, friendName: friendName),
    );
  }

  @override
  State<FriendChatScreen> createState() => _FriendChatScreenState();
}

class _FriendChatScreenState extends State<FriendChatScreen> {
  final _messageCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FriendChatSummaryProvider>().markRead(widget.friendUid);
    });
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(AppLocalizations loc) async {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty || _sending) {
      return;
    }
    setState(() => _sending = true);
    try {
      await context.read<FriendChatApi>().sendMessage(widget.friendUid, text);
      _messageCtrl.clear();
      FocusScope.of(context).unfocus();
      await context.read<FriendChatSummaryProvider>().markRead(widget.friendUid);
      _scrollToBottom();
    } catch (e) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(SnackBar(content: Text(loc.friend_chat_send_error)));
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  void _scrollToBottom() {
    if (!_scrollCtrl.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _handleMessagesUpdate(List<FriendMessage> messages, String meUid) {
    if (messages.isEmpty) return;
    final last = messages.last;
    if (last.senderId != meUid) {
      context.read<FriendChatSummaryProvider>().markRead(widget.friendUid);
    }
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final auth = context.watch<AuthProvider>();
    final meUid = auth.userId;
    if (meUid == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.friendName)),
        body: Center(child: Text(loc.friend_chat_login_required)),
      );
    }
    final stream =
        context.watch<FriendChatSource>().watchMessages(meUid, widget.friendUid);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.friendName),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<FriendMessage>>(
              stream: stream,
              builder: (context, snapshot) {
                final messages = snapshot.data ?? const <FriendMessage>[];
                if (snapshot.hasData) {
                  _handleMessagesUpdate(messages, meUid);
                }
                if (messages.isEmpty) {
                  return Center(child: Text(loc.friend_chat_empty));
                }
                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == meUid;
                    return _MessageBubble(message: message, isMe: isMe);
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageCtrl,
                      minLines: 1,
                      maxLines: 5,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(loc),
                      decoration: InputDecoration(
                        hintText: loc.friend_chat_input_hint,
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send),
                    tooltip: loc.friend_chat_send,
                    onPressed: _sending ? null : () => _sendMessage(loc),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMe});

  final FriendMessage message;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bubbleColor = isMe
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceVariant;
    final textColor = isMe
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurfaceVariant;
    final time = message.createdAt != null
        ? DateFormat.Hm().format(message.createdAt!.toLocal())
        : '';
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMe ? 16 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 16),
            ),
          ),
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message.text,
                style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
              ),
              if (time.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    time,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: textColor.withOpacity(0.7),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

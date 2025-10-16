import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:tapem/app_router.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import '../../data/friend_chat_api.dart';
import '../../data/friend_chat_source.dart';
import '../../domain/models/friend_message.dart';
import '../../providers/friend_chat_summary_provider.dart';
import '../../providers/friend_chat_messages_provider.dart';
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

class _FriendChatScreenState extends State<FriendChatScreen> with RouteAware {
  final _messageCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;
  FriendChatMessagesProvider? _messagesProvider;
  String? _lastHandledMessageId;
  ModalRoute<dynamic>? _modalRoute;
  bool _isRouteCurrent = true;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FriendChatSummaryProvider>().markRead(widget.friendUid);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null && _modalRoute != route) {
      if (_modalRoute != null) {
        routeObserver.unsubscribe(this);
      }
      _modalRoute = route;
      routeObserver.subscribe(this, route);
      _updateRouteVisibility(route.isCurrent);
    }
    _messagesProvider ??=
        FriendChatMessagesProvider(context.read<FriendChatSource>());
  }

  @override
  void didUpdateWidget(covariant FriendChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.friendUid != widget.friendUid) {
      _lastHandledMessageId = null;
    }
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _messageCtrl.dispose();
    _scrollCtrl.dispose();
    if (_modalRoute != null) {
      routeObserver.unsubscribe(this);
    }
    _messagesProvider?.setVisibility(false);
    _messagesProvider?.dispose();
    super.dispose();
  }

  void _updateRouteVisibility(bool isActive) {
    _isRouteCurrent = isActive;
    final provider = _messagesProvider;
    provider?.setVisibility(isActive);
  }

  Future<void> _sendMessage(AppLocalizations loc) async {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty || _sending) {
      return;
    }
    if (kDebugMode) {
      final preview = text.length > 120 ? '${text.substring(0, 120)}…' : text;
      debugPrint(
        '[FriendChatScreen] sendMessage start friend=${widget.friendUid} '
        'len=${text.length} preview="$preview" sending=$_sending',
      );
    }
    setState(() => _sending = true);
    try {
      await context.read<FriendChatApi>().sendMessage(widget.friendUid, text);
      _messageCtrl.clear();
      FocusScope.of(context).unfocus();
      await context.read<FriendChatSummaryProvider>().markRead(widget.friendUid);
      await _messagesProvider?.refresh();
      _scrollToBottom();
      if (kDebugMode) {
        debugPrint('[FriendChatScreen] sendMessage success friend=${widget.friendUid}');
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[FriendChatScreen] sendMessage failed friend=${widget.friendUid}: $e');
        debugPrintStack(stackTrace: st);
      }
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

  void _onScroll() {
    final provider = _messagesProvider;
    if (provider == null) return;
    if (!_scrollCtrl.hasClients) return;
    if (_scrollCtrl.position.pixels <= 120) {
      if (provider.hasMore && !provider.isLoadingMore && !provider.isLoading) {
        unawaited(provider.loadMore());
      }
    }
  }

  void _handleMessagesUpdate(List<FriendMessage> messages, String meUid) {
    if (messages.isEmpty) return;
    final last = messages.last;
    if (kDebugMode) {
      debugPrint(
        '[FriendChatScreen] messages update friend=${widget.friendUid} '
        'count=${messages.length} lastSender=${last.senderId} '
        'createdAt=${last.createdAt}',
      );
    }
    if (last.senderId != meUid) {
      context.read<FriendChatSummaryProvider>().markRead(widget.friendUid);
    }
    _lastHandledMessageId = last.id;
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final auth = context.watch<AuthProvider>();
    final meUid = auth.userId;
    final provider = _messagesProvider;
    if (meUid == null || provider == null) {
      _messagesProvider?.detach();
      return Scaffold(
        appBar: AppBar(title: Text(widget.friendName)),
        body: Center(child: Text(loc.friend_chat_login_required)),
      );
    }
    provider.listen(
      meUid: meUid,
      friendUid: widget.friendUid,
      isVisible: _isRouteCurrent,
    );
    return ChangeNotifierProvider<FriendChatMessagesProvider>.value(
      value: provider,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.friendName),
        ),
        body: Column(
          children: [
            Expanded(
              child: Consumer<FriendChatMessagesProvider>(
                builder: (context, messagesProv, _) {
                  final messages = messagesProv.messages;
                  if (messagesProv.isLoading && messages.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (messages.isNotEmpty) {
                    final lastId = messages.last.id;
                    if (_lastHandledMessageId != lastId) {
                      _handleMessagesUpdate(messages, meUid);
                    }
                  }
                  if (messages.isEmpty) {
                    return Center(child: Text(loc.friend_chat_empty));
                  }
                  final showLoader = messagesProv.hasMore;
                  final itemCount = messages.length + (showLoader ? 1 : 0);
                  return ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: itemCount,
                    itemBuilder: (context, index) {
                      if (showLoader && index == 0) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Center(
                            child: messagesProv.isLoadingMore
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        );
                      }
                      final message = messages[showLoader ? index - 1 : index];
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
      ),
    );
  }

  @override
  void didPush() {
    _updateRouteVisibility(true);
  }

  @override
  void didPopNext() {
    _updateRouteVisibility(true);
  }

  @override
  void didPushNext() {
    _updateRouteVisibility(false);
  }

  @override
  void didPop() {
    _updateRouteVisibility(false);
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

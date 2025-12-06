import 'package:flutter/material.dart';

/// Input field for sending chat messages.
///
/// Features:
/// - Multi-line text support
/// - Send button
/// - Disabled state while sending
class MessageInput extends StatefulWidget {
  const MessageInput({
    required this.onSend,
    required this.onStickerPressed,
    this.enabled = true,
    super.key,
  });

  final void Function(String text) onSend;
  final VoidCallback onStickerPressed;
  final bool enabled;

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final TextEditingController _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  void _handleSend() {
    if (!_hasText || !widget.enabled) return;

    final text = _controller.text.trim();
    if (text.isEmpty) return;

    widget.onSend(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              onPressed: widget.enabled ? widget.onStickerPressed : null,
              icon: const Icon(Icons.emoji_emotions_outlined),
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: widget.enabled,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Nachricht schreiben...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) => _handleSend(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _hasText && widget.enabled ? _handleSend : null,
              icon: const Icon(Icons.send),
              color: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}

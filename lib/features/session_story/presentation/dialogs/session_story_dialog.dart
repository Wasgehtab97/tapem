import 'package:flutter/material.dart';

import 'package:tapem/features/session_story/domain/models/session_story.dart';
import 'package:tapem/features/session_story/presentation/widgets/session_story_card.dart';

Future<void> showSessionStoryDialog({
  required BuildContext context,
  required SessionStory story,
  VoidCallback? onClosed,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: SessionStoryCard(
        story: story,
        onClose: () {
          Navigator.of(ctx).maybePop();
          onClosed?.call();
        },
      ),
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tapem/features/session_story/presentation/dialogs/session_story_dialog.dart';
import 'package:tapem/features/session_story/providers/session_story_provider.dart';

class SessionStoryPopupListener extends StatefulWidget {
  final Widget child;

  const SessionStoryPopupListener({super.key, required this.child});

  @override
  State<SessionStoryPopupListener> createState() => _SessionStoryPopupListenerState();
}

class _SessionStoryPopupListenerState extends State<SessionStoryPopupListener> {
  @override
  Widget build(BuildContext context) {
    return Consumer<SessionStoryProvider>(
      builder: (context, provider, child) {
        final pending = provider.pendingPopup;
        if (provider.showPopup && pending != null && !provider.dialogVisible) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            provider.markDialogVisible(true);
            await showSessionStoryDialog(
              context: context,
              story: pending,
              onClosed: () {
                provider.markDialogVisible(false);
                provider.dismissPopup();
              },
            );
          });
        }
        return child!;
      },
      child: widget.child,
    );
  }
}

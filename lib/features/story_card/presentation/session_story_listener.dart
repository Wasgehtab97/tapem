import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tapem/core/logging/elog.dart';
import '../session_story_controller.dart';
import '../session_story_share_service.dart';
import '../story_link_builder.dart';
import '../domain/session_story_data.dart';
import 'widgets/session_story_modal.dart';

class SessionStoryListener extends StatefulWidget {
  final Widget child;

  const SessionStoryListener({super.key, required this.child});

  @override
  State<SessionStoryListener> createState() => _SessionStoryListenerState();
}

class _SessionStoryListenerState extends State<SessionStoryListener> {
  final SessionStoryShareService _shareService = SessionStoryShareService();
  final StoryLinkBuilder _linkBuilder = StoryLinkBuilder();
  bool _isShowing = false;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SessionStoryController>();
    if (!_isShowing && controller.hasPendingStory) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showPending(controller);
      });
    }
    return widget.child;
  }

  Future<void> _showPending(SessionStoryController controller) async {
    if (_isShowing) return;
    final story = controller.consumePending();
    if (story == null) return;
    setState(() => _isShowing = true);
    await SessionStoryModal.show(
      context: context,
      story: story,
      shareService: _shareService,
      buildLink: () => _linkBuilder.build(story),
      onShared: (target) {
        elogUi('storycard_shared', {
          'sessionId': story.sessionId,
          'target': target ?? 'system',
        });
      },
      onSaved: () {
        elogUi('storycard_saved', {'sessionId': story.sessionId});
      },
      onViewed: () {
        elogUi('storycard_shown', {
          'sessionId': story.sessionId,
          'origin': 'auto',
          'xpTotal': story.xpTotal,
          'prCount': story.badges.length,
        });
      },
    );
    if (mounted) {
      setState(() => _isShowing = false);
    }
  }
}

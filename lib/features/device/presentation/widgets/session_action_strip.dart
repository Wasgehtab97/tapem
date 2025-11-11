import 'package:flutter/material.dart';

import 'session_action_button_style.dart';

class SessionActionStrip extends StatelessWidget {
  const SessionActionStrip({
    super.key,
    this.onOpenLeaderboard,
    this.onOpenHistory,
    this.onToggleBodyweight,
    this.onFeedback,
    required this.isBodyweightMode,
    this.leaderboardTooltip,
    this.historyTooltip,
    this.bodyweightTooltip,
    this.feedbackTooltip,
    this.preFeedbackActions = const <Widget>[],
    this.postFeedbackActions = const <Widget>[],
    this.trailing,
  });

  final VoidCallback? onOpenLeaderboard;
  final VoidCallback? onOpenHistory;
  final VoidCallback? onToggleBodyweight;
  final VoidCallback? onFeedback;
  final bool isBodyweightMode;
  final String? leaderboardTooltip;
  final String? historyTooltip;
  final String? bodyweightTooltip;
  final String? feedbackTooltip;
  final List<Widget> preFeedbackActions;
  final List<Widget> postFeedbackActions;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final actions = _buildActions(context);
    final trailing = this.trailing;

    if (actions.isEmpty && trailing == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: actions.isEmpty
                ? const SizedBox.shrink()
                : Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: actions,
                  ),
          ),
          if (trailing != null) ...[
            if (actions.isNotEmpty) const SizedBox(width: 8),
            Align(
              alignment: Alignment.centerRight,
              child: trailing,
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    final actions = <Widget>[];

    if (onOpenLeaderboard != null) {
      actions.add(_buildIconButton(
        context,
        icon: Icons.emoji_events_outlined,
        tooltip: leaderboardTooltip,
        onPressed: onOpenLeaderboard,
      ));
    }

    if (onOpenHistory != null) {
      actions.add(_buildIconButton(
        context,
        icon: Icons.history,
        tooltip: historyTooltip,
        onPressed: onOpenHistory,
      ));
    }

    if (onToggleBodyweight != null) {
      actions.add(_buildIconButton(
        context,
        icon: Icons.accessibility_new,
        tooltip: bodyweightTooltip,
        onPressed: onToggleBodyweight,
        isActive: isBodyweightMode,
      ));
    }

    for (final widget in preFeedbackActions) {
      actions.add(widget);
    }

    if (onFeedback != null) {
      actions.add(_buildIconButton(
        context,
        icon: Icons.feedback_outlined,
        tooltip: feedbackTooltip,
        onPressed: onFeedback,
      ));
    }

    for (final widget in postFeedbackActions) {
      actions.add(widget);
    }

    return actions;
  }

  Widget _buildIconButton(
    BuildContext context, {
    required IconData icon,
    required String? tooltip,
    required VoidCallback? onPressed,
    bool isActive = false,
  }) {
    return IconButton(
      icon: Icon(icon),
      tooltip: tooltip,
      onPressed: onPressed,
      style: sessionActionButtonStyle(
        context,
        isActive: isActive,
      ),
    );
  }
}

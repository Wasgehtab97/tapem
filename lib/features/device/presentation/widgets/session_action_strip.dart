import 'package:flutter/material.dart';

class SessionActionStrip extends StatelessWidget {
  const SessionActionStrip({
    super.key,
    this.onOpenLeaderboard,
    this.onOpenHistory,
    this.onToggleBodyweight,
    this.onFeedback,
    required this.isBodyweightMode,
    required this.accentColor,
    this.leaderboardTooltip,
    this.historyTooltip,
    this.bodyweightTooltip,
    this.feedbackTooltip,
    this.preFeedbackActions = const <Widget>[],
    this.postFeedbackActions = const <Widget>[],
  });

  final VoidCallback? onOpenLeaderboard;
  final VoidCallback? onOpenHistory;
  final VoidCallback? onToggleBodyweight;
  final VoidCallback? onFeedback;
  final bool isBodyweightMode;
  final Color accentColor;
  final String? leaderboardTooltip;
  final String? historyTooltip;
  final String? bodyweightTooltip;
  final String? feedbackTooltip;
  final List<Widget> preFeedbackActions;
  final List<Widget> postFeedbackActions;

  @override
  Widget build(BuildContext context) {
    final actions = _buildActions(context);
    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    final iconButtonTheme = IconButtonTheme.of(context);
    final compactStyle = iconButtonTheme.style?.copyWith(
          padding: MaterialStateProperty.all(const EdgeInsets.all(4)),
          visualDensity: MaterialStateProperty.all(VisualDensity.compact),
          tapTargetSize: MaterialStateProperty.all(MaterialTapTargetSize.shrinkWrap),
          minimumSize: MaterialStateProperty.all(const Size.square(36)),
        ) ??
        IconButton.styleFrom(
          padding: const EdgeInsets.all(4),
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          minimumSize: const Size.square(36),
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: IconButtonTheme(
        data: IconButtonThemeData(style: compactStyle),
        child: Wrap(
          spacing: 4,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: actions,
        ),
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    final actions = <Widget>[];

    if (onOpenLeaderboard != null) {
      actions.add(
        IconButton(
          icon: const Icon(Icons.emoji_events_outlined),
          tooltip: leaderboardTooltip,
          onPressed: onOpenLeaderboard,
        ),
      );
    }

    if (onOpenHistory != null) {
      actions.add(
        IconButton(
          icon: const Icon(Icons.history),
          tooltip: historyTooltip,
          onPressed: onOpenHistory,
        ),
      );
    }

    if (onToggleBodyweight != null) {
      actions.add(
        IconButton(
          icon: Icon(
            Icons.accessibility_new,
            color: isBodyweightMode ? Theme.of(context).colorScheme.primary : accentColor,
          ),
          tooltip: bodyweightTooltip,
          onPressed: onToggleBodyweight,
        ),
      );
    }

    for (final widget in preFeedbackActions) {
      actions.add(widget);
    }

    if (onFeedback != null) {
      actions.add(
        IconButton(
          icon: Icon(Icons.feedback_outlined, color: accentColor),
          tooltip: feedbackTooltip,
          onPressed: onFeedback,
        ),
      );
    }

    for (final widget in postFeedbackActions) {
      actions.add(widget);
    }

    return actions;
  }
}

import 'package:flutter/material.dart';
import 'package:tapem/ui/timer/active_workout_timer.dart';

class SessionActionStrip extends StatelessWidget {
  const SessionActionStrip({
    super.key,
    required this.title,
    this.subtitle,
    this.onClose,
    this.sessionKey,
    this.nfcButton,
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
    this.closeTooltip,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onClose;
  final String? sessionKey;
  final Widget? nfcButton;
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
  final String? closeTooltip;

  @override
  Widget build(BuildContext context) {
    final timerKey = sessionKey != null
        ? ValueKey('deviceSessionTimer-$sessionKey')
        : const ValueKey('deviceSessionTimer');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ) ??
                          const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 8),
                    ActiveWorkoutTimer(
                      key: timerKey,
                      padding: EdgeInsets.zero,
                      compact: true,
                      sessionKey: sessionKey,
                    ),
                  ],
                ),
              ),
              if (onClose != null)
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: closeTooltip,
                  onPressed: onClose,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            children: [
              if (nfcButton != null) nfcButton!,
              Row(
                mainAxisSize: MainAxisSize.min,
                children: _buildActions(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    final actions = <Widget>[];
    void addSpacing() {
      if (actions.isNotEmpty) {
        actions.add(const SizedBox(width: 4));
      }
    }

    if (onOpenLeaderboard != null) {
      addSpacing();
      actions.add(
        IconButton(
          icon: const Icon(Icons.emoji_events_outlined),
          tooltip: leaderboardTooltip,
          onPressed: onOpenLeaderboard,
        ),
      );
    }

    if (onOpenHistory != null) {
      addSpacing();
      actions.add(
        IconButton(
          icon: const Icon(Icons.history),
          tooltip: historyTooltip,
          onPressed: onOpenHistory,
        ),
      );
    }

    if (onToggleBodyweight != null) {
      addSpacing();
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
      addSpacing();
      actions.add(widget);
    }

    if (onFeedback != null) {
      addSpacing();
      actions.add(
        IconButton(
          icon: Icon(Icons.feedback_outlined, color: accentColor),
          tooltip: feedbackTooltip,
          onPressed: onFeedback,
        ),
      );
    }

    for (final widget in postFeedbackActions) {
      addSpacing();
      actions.add(widget);
    }

    return actions;
  }
}

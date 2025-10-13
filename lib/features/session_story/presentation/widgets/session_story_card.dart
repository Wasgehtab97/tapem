import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:tapem/core/providers/muscle_group_provider.dart';
import 'package:tapem/features/session_story/domain/models/session_story.dart';
import 'package:tapem/features/session_story/presentation/utils/session_story_share.dart';
import 'package:tapem/l10n/app_localizations.dart';

class SessionStoryCard extends StatelessWidget {
  final SessionStory story;
  final VoidCallback onClose;

  const SessionStoryCard({super.key, required this.story, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final dateFormatter = DateFormat.yMMMMd(locale);
    final muscleProvider = context.watch<MuscleGroupProvider?>();
    final Map<String, String> muscleNames = {
      for (final group in muscleProvider?.groups ?? const [])
        group.id: group.name,
    };
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.95),
              Theme.of(context).colorScheme.secondary.withOpacity(0.9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.sessionStoryTitle,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        loc.sessionStorySubtitle(dateFormatter.format(story.day)),
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close, color: Colors.white70),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildHighlights(context, loc, locale),
            const SizedBox(height: 16),
            _buildXpSummary(context, loc, muscleNames),
            const SizedBox(height: 24),
            Row(
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: () {
                    final text = buildSessionStoryShareText(
                      story,
                      loc,
                      locale,
                      muscleNames,
                    );
                    Share.share(text, subject: loc.sessionStoryShareSubject);
                  },
                  icon: const Icon(Icons.ios_share),
                  label: Text(loc.sessionStoryShareButton),
                ),
                const SizedBox(width: 12),
                if (story.totalDuration != null)
                  Text(
                    loc.sessionStoryDuration(
                      DateFormat.Hm().format(DateTime(0).add(story.totalDuration!)),
                    ),
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.white70),
                  ),
                const Spacer(),
                FilledButton(
                  onPressed: onClose,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white10,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(loc.sessionStoryCloseButton),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlights(BuildContext context, AppLocalizations loc, String locale) {
    if (story.highlights.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.sessionStoryHighlightsTitle,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            loc.sessionStoryHighlightsEmpty,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.white70),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.sessionStoryHighlightsTitle,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        ...story.highlights.map((highlight) {
          final icon = _highlightIcon(highlight.type);
          final title = _highlightTitle(loc, highlight, locale);
          final subtitle = _highlightSubtitle(loc, highlight, locale);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.white70),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildXpSummary(
    BuildContext context,
    AppLocalizations loc,
    Map<String, String> muscleNames,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.sessionStoryXpTitle,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.sessionStoryXpDailyLabel(story.xpSummary.dailyXp),
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              if (story.xpSummary.deviceXp.isNotEmpty) ...[
                Text(
                  loc.sessionStoryXpDevicesTitle,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(color: Colors.white70, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                ...story.xpSummary.deviceXp.map((entry) {
                  final exercises = entry.exerciseNames.isEmpty
                      ? null
                      : entry.exerciseNames.join(', ');
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.canonicalDeviceName,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                              ),
                              if (exercises != null)
                                Text(
                                  exercises,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: Colors.white70),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          '${entry.xp} XP',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 12),
              ],
              if (story.xpSummary.muscleXp.isNotEmpty) ...[
                Text(
                  loc.sessionStoryXpMusclesTitle,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(color: Colors.white70, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                ...story.xpSummary.muscleXp.map((entry) {
                  final name = muscleNames[entry.muscleGroupId] ?? entry.muscleGroupId;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          '${entry.xp} XP',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ],
    );
  }

  IconData _highlightIcon(SessionStoryHighlightType type) {
    switch (type) {
      case SessionStoryHighlightType.firstDevice:
        return Icons.fitness_center;
      case SessionStoryHighlightType.firstExercise:
        return Icons.auto_awesome;
      case SessionStoryHighlightType.e1rmPr:
        return Icons.trending_up;
      case SessionStoryHighlightType.volumePr:
        return Icons.bar_chart;
    }
  }

  String _highlightTitle(
    AppLocalizations loc,
    SessionStoryHighlight highlight,
    String locale,
  ) {
    switch (highlight.type) {
      case SessionStoryHighlightType.firstDevice:
        return loc.sessionStoryHighlightFirstDeviceTitle(highlight.canonicalDeviceName);
      case SessionStoryHighlightType.firstExercise:
        return loc.sessionStoryHighlightFirstExerciseTitle(
          highlight.exerciseName ?? highlight.deviceName,
        );
      case SessionStoryHighlightType.e1rmPr:
        final formatted = NumberFormat('#,##0.0', locale).format(highlight.metricValue ?? 0);
        return loc.sessionStoryHighlightE1rmTitle(formatted);
      case SessionStoryHighlightType.volumePr:
        final formatted = NumberFormat('#,##0', locale).format(highlight.metricValue ?? 0);
        return loc.sessionStoryHighlightVolumeTitle(formatted);
    }
  }

  String? _highlightSubtitle(
    AppLocalizations loc,
    SessionStoryHighlight highlight,
    String locale,
  ) {
    switch (highlight.type) {
      case SessionStoryHighlightType.firstDevice:
        return '${loc.sessionStoryHighlightFirstDeviceSubtitle}: ${highlight.canonicalDeviceName}';
      case SessionStoryHighlightType.firstExercise:
        return highlight.canonicalDeviceName;
      case SessionStoryHighlightType.e1rmPr:
        return highlight.exerciseName ?? highlight.canonicalDeviceName;
      case SessionStoryHighlightType.volumePr:
        return highlight.exerciseName ?? highlight.canonicalDeviceName;
    }
  }
}

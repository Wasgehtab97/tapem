import 'package:intl/intl.dart';

import 'package:tapem/features/session_story/domain/models/session_story.dart';
import 'package:tapem/l10n/app_localizations.dart';

String buildSessionStoryShareText(
  SessionStory story,
  AppLocalizations loc,
  String locale,
  Map<String, String> muscleNames,
) {
  final buffer = StringBuffer();
  final dateFormatter = DateFormat.yMMMMd(locale);
  buffer.writeln(
    loc.sessionStoryShareTitle(dateFormatter.format(story.day)),
  );

  if (story.highlights.isNotEmpty) {
    final highlightTexts = story.highlights.map((highlight) {
      switch (highlight.type) {
        case SessionStoryHighlightType.firstDevice:
          return loc.sessionStoryShareHighlightFirstDevice(highlight.canonicalDeviceName);
        case SessionStoryHighlightType.firstExercise:
          return loc.sessionStoryShareHighlightFirstExercise(
            highlight.exerciseName ?? highlight.deviceName,
          );
        case SessionStoryHighlightType.e1rmPr:
          final weight = NumberFormat('#,##0.0', locale).format(highlight.metricValue ?? 0);
          return loc.sessionStoryShareHighlightE1rm(
            weight,
            highlight.deviceName,
          );
        case SessionStoryHighlightType.volumePr:
          final volume = NumberFormat('#,##0', locale).format(highlight.metricValue ?? 0);
          return loc.sessionStoryShareHighlightVolume(
            volume,
            highlight.deviceName,
          );
      }
    }).toList();
    buffer.writeln(loc.sessionStoryShareHighlights(highlightTexts.join(', ')));
  }

  buffer.writeln(loc.sessionStoryShareDailyXp(story.xpSummary.dailyXp));

  if (story.xpSummary.deviceXp.isNotEmpty) {
    final entries = story.xpSummary.deviceXp.map((entry) {
      final label = entry.exerciseNames.isEmpty
          ? entry.canonicalDeviceName
          : '${entry.canonicalDeviceName} (${entry.exerciseNames.join(', ')})';
      return '$label: ${entry.xp} XP';
    }).join(', ');
    buffer.writeln(loc.sessionStoryShareDeviceXp(entries));
  }

  if (story.xpSummary.muscleXp.isNotEmpty) {
    final parts = story.xpSummary.muscleXp.map((entry) {
      final name = muscleNames[entry.muscleGroupId] ?? entry.muscleGroupId;
      return '$name: ${entry.xp} XP';
    }).join(', ');
    buffer.writeln(loc.sessionStoryShareMuscleXp(parts));
  }

  return buffer.toString().trim();
}

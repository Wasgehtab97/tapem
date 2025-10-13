// lib/features/training_details/presentation/screens/training_details_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:tapem/core/providers/training_details_provider.dart';
import 'package:tapem/core/providers/branding_provider.dart';
import '../widgets/day_sessions_overview.dart';
import 'package:tapem/core/utils/duration_format.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/features/story_card/session_story_controller.dart';
import 'package:tapem/features/story_card/data/story_analytics_service.dart';
import 'package:tapem/features/story_card/session_story_share_service.dart';
import 'package:tapem/features/story_card/presentation/widgets/session_story_modal.dart';
import 'package:tapem/features/story_card/story_link_builder.dart';
import 'package:tapem/core/logging/elog.dart';

class TrainingDetailsScreen extends StatelessWidget {
  final DateTime date;
  final String userId;

  const TrainingDetailsScreen({Key? key, required this.date, required this.userId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final gymId = context.read<BrandingProvider>().gymId!;
    return ChangeNotifierProvider<TrainingDetailsProvider>(
      create: (_) {
        final prov = TrainingDetailsProvider();
        prov.loadSessions(userId: userId, date: date, gymId: gymId);
        return prov;
      },
      child: Consumer<TrainingDetailsProvider>(
        builder: (ctx, prov, _) {
          // Loading state
          if (prov.isLoading) {
            return const Scaffold(
              appBar: _AppBar(titleDate: null),
              body: Center(child: CircularProgressIndicator()),
            );
          }
          // Error state
          if (prov.error != null) {
            return Scaffold(
              appBar: _AppBar(titleDate: date),
              body: Center(child: Text('Fehler: ${prov.error}')),
            );
          }
          // Data state
          final sessions = prov.sessions;
          final duration = prov.dayDurationMs;
          final loc = AppLocalizations.of(ctx)!;
          final storyController = ctx.read<SessionStoryController>();
          final storySessionId = prov.storySessionId;
          return Scaffold(
            appBar: _AppBar(
              titleDate: date,
              durationMs: duration,
              onShowStory: storySessionId == null
                  ? null
                  : () =>
                      _openStory(context, storyController, storySessionId),
            ),
            body: sessions.isEmpty
                ? const Center(child: Text('Keine Trainingseinheiten'))
                : Scrollbar(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: DaySessionsOverview(
                        sessions: sessions,
                        onSessionLongPress: (session) async {
                          final confirmed = await showDialog<bool>(
                            context: ctx,
                            builder: (dialogCtx) => AlertDialog(
                              title: Text(
                                loc.trainingDetailsDeleteSessionTitle,
                              ),
                              content: Text(
                                loc.trainingDetailsDeleteSessionMessage,
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(dialogCtx).pop(false),
                                  child: Text(loc.commonCancel),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(dialogCtx).pop(true),
                                  style: TextButton.styleFrom(
                                      foregroundColor: Colors.red),
                                  child: Text(
                                    loc.trainingDetailsDeleteSessionConfirm,
                                  ),
                                ),
                              ],
                            ),
                          );
                          if (confirmed != true) {
                            return;
                          }
                          try {
                            await prov.deleteSession(session);
                            if (!ctx.mounted) return;
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text(
                                  loc.trainingDetailsDeleteSessionSuccess,
                                ),
                              ),
                            );
                          } catch (_) {
                            if (!ctx.mounted) return;
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text(
                                  loc.trainingDetailsDeleteSessionError,
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }
}

/// Custom AppBar that shows the selected date in the accent colour.
class _AppBar extends StatelessWidget implements PreferredSizeWidget {
  final DateTime? titleDate;
  final int? durationMs;
  final VoidCallback? onShowStory;
  const _AppBar({this.titleDate, this.durationMs, this.onShowStory});

  @override
  Widget build(BuildContext context) {
    final title =
        titleDate != null
            ? DateFormat.yMMMMd(
              Localizations.localeOf(context).toString(),
            ).format(titleDate!)
            : 'Training Details';

    Widget titleWidget = Text(
      title,
      style: TextStyle(color: Theme.of(context).colorScheme.secondary),
    );
    if (durationMs != null) {
      final dur = Duration(milliseconds: durationMs!);
      final formatted = formatDurationHm(dur);
      titleWidget = Row(
        children: [
          Expanded(
            child: Text(
              title,
              style:
                  TextStyle(color: Theme.of(context).colorScheme.secondary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '⏱ $formatted',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      );
    }
    return AppBar(
      title: titleWidget,
      actions: [
        Builder(
          builder: (context) {
            final loc = AppLocalizations.of(context)!;
            return IconButton(
              tooltip: loc.storycardHeaderTooltip,
              icon: const Icon(Icons.auto_awesome),
              onPressed: onShowStory,
            );
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

Future<void> _openStory(
  BuildContext context,
  SessionStoryController controller,
  String sessionId,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final loc = AppLocalizations.of(context)!;
  final shareService = SessionStoryShareService();
  final linkBuilder = StoryLinkBuilder();
  final analytics = StoryAnalyticsService();
  final userId = context.read<AuthProvider?>()?.userId ?? '';
  debugPrint('📖 [TrainingDetails] open story request sessionId=$sessionId');
  try {
    final story = await controller.loadStoryById(sessionId);
    debugPrint(
      '📖 [TrainingDetails] story loaded sessionId=${story.sessionId} xp=${story.xpTotal} badges=${story.badges.length}',
    );
    await SessionStoryModal.show(
      context: context,
      story: story,
      shareService: shareService,
      buildLink: () => linkBuilder.build(story),
      onViewed: () {
        elogUi('storycard_shown', {
          'sessionId': story.sessionId,
          'origin': 'header',
          'xpTotal': story.xpTotal,
          'prCount': story.badges.length,
        });
        analytics.trackStoryViewed(userId: userId, sessionId: story.sessionId);
      },
      onShared: (target) {
        elogUi('storycard_shared', {
          'sessionId': story.sessionId,
          'target': target ?? 'system',
        });
        analytics.trackStoryShared(
          userId: userId,
          sessionId: story.sessionId,
          target: target,
        );
      },
      onSaved: () {
        elogUi('storycard_saved', {'sessionId': story.sessionId});
        analytics.trackStorySaved(userId: userId, sessionId: story.sessionId);
      },
    );
  } catch (error, stack) {
    debugPrint(
      '❌ [TrainingDetails] story load failed sessionId=$sessionId error=$error\n$stack',
    );
    messenger.showSnackBar(
      SnackBar(content: Text(loc.storycardLoadError)),
    );
  }
}

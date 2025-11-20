// lib/features/training_details/presentation/screens/training_details_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider;
import 'package:intl/intl.dart';

import 'package:tapem/core/providers/database_provider.dart';
import 'package:tapem/core/providers/training_details_provider.dart';
import 'package:tapem/core/providers/branding_provider.dart';
import 'package:tapem/features/training_details/domain/models/session.dart';
import 'package:tapem/features/story_session/presentation/widgets/story_session_dialog.dart';
import 'package:tapem/features/story_session/story_session_service.dart';
import '../widgets/day_sessions_overview.dart';
import 'package:tapem/core/utils/duration_format.dart';
import 'package:tapem/l10n/app_localizations.dart';

class TrainingDetailsScreen extends ConsumerWidget {
  final DateTime date;
  final String userId;
  final String? gymId;

  const TrainingDetailsScreen({
    Key? key,
    required this.date,
    required this.userId,
    this.gymId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fallbackGymId = gymId ?? context.read<BrandingProvider>().gymId;
    final databaseService = ref.read(databaseServiceProvider);
    final syncService = ref.read(syncServiceProvider);

    return provider.ChangeNotifierProvider<TrainingDetailsProvider>(
      create: (_) {
        final prov = TrainingDetailsProvider(databaseService, syncService);
        prov.loadSessions(userId: userId, date: date, gymId: fallbackGymId);
        return prov;
      },
      child: provider.Consumer<TrainingDetailsProvider>(
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
          Future<void> openStory() async {
            final storyService = ctx.read<StorySessionService>();
            final navigator = Navigator.of(ctx);
            final messenger = ScaffoldMessenger.of(ctx);
            final resolvedGymId = prov.gymId ?? fallbackGymId;
            if (resolvedGymId == null) {
              debugPrint('⚠️ storySession: missing gymId for summary');
              return;
            }
            final summary = await storyService.getSummary(
              gymId: resolvedGymId,
              userId: userId,
              date: date,
              sessions: sessions,
            );
            if (summary == null || summary.achievements.isEmpty) {
              messenger.showSnackBar(
                SnackBar(content: Text(loc.storySessionEmptyMessage)),
              );
              return;
            }
            if (!navigator.mounted) return;
            await showDialog<void>(
              context: navigator.context,
              builder: (_) => StorySessionDialog(summary: summary),
            );
          }

          return Scaffold(
            appBar: _AppBar(
              titleDate: date,
              durationMs: duration,
              onStoryPressed: sessions.isEmpty ||
                      (prov.gymId ?? fallbackGymId) == null
                  ? null
                  : openStory,
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
  final VoidCallback? onStoryPressed;
  const _AppBar({this.titleDate, this.durationMs, this.onStoryPressed});

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
        if (onStoryPressed != null)
          IconButton(
            icon: const Icon(Icons.auto_stories_outlined),
            onPressed: onStoryPressed,
            tooltip: AppLocalizations.of(context)!.storySessionButtonTooltip,
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

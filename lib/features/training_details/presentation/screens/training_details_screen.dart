// lib/features/training_details/presentation/screens/training_details_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:tapem/app_router.dart';

import 'package:tapem/core/providers/database_provider.dart';
import 'package:tapem/core/providers/training_details_provider.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/features/training_details/domain/models/session.dart';
import 'package:tapem/features/story_session/presentation/widgets/story_session_dialog.dart';
import 'package:tapem/features/story_session/story_session_service.dart';
import 'package:tapem/features/training_plan/application/create_training_plan_from_day_usecase.dart';
import 'package:tapem/features/training_plan/application/training_plan_provider.dart';
import '../widgets/day_sessions_overview.dart';
import 'package:tapem/core/utils/duration_format.dart';
import 'package:tapem/l10n/app_localizations.dart';

class TrainingDetailsScreen extends ConsumerStatefulWidget {
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
  ConsumerState<TrainingDetailsScreen> createState() =>
      _TrainingDetailsScreenState();
}

class _TrainingDetailsScreenState extends ConsumerState<TrainingDetailsScreen> {
  bool _isCreatingPlanFromDay = false;

  @override
  Widget build(BuildContext context) {
    final authView = ref.watch(authViewStateProvider);
    final fallbackGymId = widget.gymId ?? authView.gymCode;

    final request = TrainingDetailsRequest(
      userId: widget.userId,
      date: widget.date,
      gymId: fallbackGymId,
    );
    final prov = ref.watch(trainingDetailsStateProvider(request));

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
        appBar: _AppBar(titleDate: widget.date),
        body: Center(child: Text('Fehler: ${prov.error}')),
      );
    }

    // Data state
    final sessions = prov.sessions;
    final duration = prov.dayDurationMs;
    final loc = AppLocalizations.of(context)!;
    final currentUserId = authView.userId;
    final resolvedGymId = prov.gymId ?? fallbackGymId;
    final canCreatePlanFromDay =
        sessions.isNotEmpty &&
        resolvedGymId != null &&
        resolvedGymId.isNotEmpty &&
        currentUserId != null &&
        currentUserId == widget.userId;

    Future<void> openStory() async {
      final storyService = ref.read(storySessionServiceProvider);
      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);
      if (resolvedGymId == null) {
        debugPrint('⚠️ storySession: missing gymId for summary');
        return;
      }
      final summary = await storyService.getSummary(
        gymId: resolvedGymId,
        userId: widget.userId,
        date: widget.date,
        sessions: sessions,
        fallbackDurationMs: duration,
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

    Future<void> createPlanFromDay() async {
      if (!canCreatePlanFromDay) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.trainingDetailsCreatePlanErrorNotAllowed)),
        );
        return;
      }
      if (_isCreatingPlanFromDay) {
        return;
      }
      final effectiveGymId = resolvedGymId;
      final effectiveUserId = currentUserId;
      final planName = await showDialog<String>(
        context: context,
        barrierColor: Colors.black54,
        builder: (_) => const CreatePlanFromDayDialog(),
      );
      if (planName == null || planName.trim().isEmpty) {
        return;
      }
      if (!context.mounted) return;
      setState(() => _isCreatingPlanFromDay = true);
      debugPrint(
        '📋 [TrainingPlan] create_from_day_started day=${widget.date.toIso8601String()} sessions=${sessions.length}',
      );

      var isProgressDialogOpen = true;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      ).then((_) {
        isProgressDialogOpen = false;
      });

      void closeProgressDialog() {
        if (!isProgressDialogOpen || !context.mounted) return;
        isProgressDialogOpen = false;
        Navigator.of(context, rootNavigator: true).pop();
      }

      try {
        final result = await ref
            .read(createTrainingPlanFromDayUseCaseProvider)
            .execute(
              userId: effectiveUserId,
              gymId: effectiveGymId,
              planName: planName,
              sessions: sessions,
            );
        ref.invalidate(trainingPlansProvider);
        closeProgressDialog();
        if (!context.mounted) return;
        debugPrint(
          '📋 [TrainingPlan] create_from_day_succeeded planId=${result.plan.id} exercises=${result.plan.exercises.length} duplicatesRemoved=${result.duplicatesRemoved} invalidSessionsSkipped=${result.invalidSessionsSkipped}',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              loc.trainingDetailsCreatePlanSuccess(result.plan.name),
            ),
          ),
        );
        Navigator.of(
          context,
        ).pushNamed(AppRouter.trainingPlanDetail, arguments: result.plan);
      } on CreateTrainingPlanFromDayException catch (error) {
        closeProgressDialog();
        if (!context.mounted) return;
        debugPrint(
          '❌ [TrainingPlan] create_from_day_failed code=${error.code} message=${error.message}',
        );
        final message = switch (error.code) {
          CreateTrainingPlanFromDayErrorCode.invalidPlanName =>
            loc.trainingDetailsCreatePlanErrorInvalidName,
          CreateTrainingPlanFromDayErrorCode.missingUserContext ||
          CreateTrainingPlanFromDayErrorCode.missingGymContext =>
            loc.trainingDetailsCreatePlanErrorNotAllowed,
          CreateTrainingPlanFromDayErrorCode.noExercisesFound =>
            loc.trainingDetailsCreatePlanErrorNoExercises,
        };
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      } catch (_) {
        closeProgressDialog();
        if (!context.mounted) return;
        debugPrint('❌ [TrainingPlan] create_from_day_failed code=unknown');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.trainingDetailsCreatePlanErrorGeneric)),
        );
      } finally {
        if (mounted) {
          setState(() => _isCreatingPlanFromDay = false);
        }
      }
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _AppBar(
        titleDate: widget.date,
        durationMs: duration,
        onCreatePlanPressed: canCreatePlanFromDay ? createPlanFromDay : null,
        isCreatingPlan: _isCreatingPlanFromDay,
        onStoryPressed: sessions.isEmpty || resolvedGymId == null
            ? null
            : openStory,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              Color.alphaBlend(
                (Theme.of(context).extension<AppBrandTheme>()?.outline ??
                        Theme.of(context).colorScheme.secondary)
                    .withOpacity(0.05),
                Theme.of(context).scaffoldBackgroundColor,
              ),
            ],
          ),
        ),
        child: SafeArea(
          child: sessions.isEmpty
              ? const Center(child: Text('Keine Trainingseinheiten'))
              : Scrollbar(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (prov.planName != null)
                          _PlanTag(planName: prov.planName!),
                        DaySessionsOverview(
                          sessions: sessions,
                          onSessionLongPress: (session) async {
                            final confirmed = await showDialog<bool>(
                              context: context,
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
                                      foregroundColor: Colors.red,
                                    ),
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
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    loc.trainingDetailsDeleteSessionSuccess,
                                  ),
                                ),
                              );
                            } catch (_) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    loc.trainingDetailsDeleteSessionError,
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

/// Custom AppBar that shows the selected date in the accent colour.
class _AppBar extends StatelessWidget implements PreferredSizeWidget {
  final DateTime? titleDate;
  final int? durationMs;
  final VoidCallback? onCreatePlanPressed;
  final bool isCreatingPlan;
  final VoidCallback? onStoryPressed;
  const _AppBar({
    this.titleDate,
    this.durationMs,
    this.onCreatePlanPressed,
    this.isCreatingPlan = false,
    this.onStoryPressed,
  });

  @override
  Widget build(BuildContext context) {
    final title = titleDate != null
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
              style: TextStyle(color: Theme.of(context).colorScheme.secondary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text('⏱ $formatted', style: Theme.of(context).textTheme.bodyMedium),
        ],
      );
    }
    return AppBar(
      title: titleWidget,
      actions: [
        if (onCreatePlanPressed != null)
          IconButton(
            icon: isCreatingPlan
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.playlist_add_rounded),
            onPressed: isCreatingPlan ? null : onCreatePlanPressed,
            tooltip: AppLocalizations.of(
              context,
            )!.trainingDetailsCreatePlanTooltip,
          ),
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

class CreatePlanFromDayDialog extends StatefulWidget {
  const CreatePlanFromDayDialog({super.key});

  @override
  State<CreatePlanFromDayDialog> createState() =>
      _CreatePlanFromDayDialogState();
}

class _CreatePlanFromDayDialogState extends State<CreatePlanFromDayDialog> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final name = _nameController.text.trim();
    final canCreate = name.isNotEmpty && name.length <= 60;
    return AlertDialog(
      title: Text(loc.trainingDetailsCreatePlanDialogTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(loc.trainingDetailsCreatePlanDialogMessage),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: loc.trainingDetailsCreatePlanDialogHint,
              helperText: '${name.length}/60',
            ),
            onSubmitted: (_) {
              final normalized = _nameController.text.trim();
              if (normalized.isEmpty || normalized.length > 60) return;
              Navigator.of(context).pop(normalized);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(loc.commonCancel),
        ),
        FilledButton(
          onPressed: canCreate
              ? () => Navigator.of(context).pop(_nameController.text.trim())
              : null,
          child: Text(loc.trainingDetailsCreatePlanDialogConfirm),
        ),
      ],
    );
  }
}

class _PlanTag extends StatelessWidget {
  const _PlanTag({required this.planName});
  final String planName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color =
        theme.extension<AppBrandTheme>()?.outline ??
        theme.colorScheme.secondary;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withOpacity(0.15),
            child: Icon(Icons.bolt_rounded, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Training mit Plan',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  planName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_outward_rounded, color: color),
        ],
      ),
    );
  }
}

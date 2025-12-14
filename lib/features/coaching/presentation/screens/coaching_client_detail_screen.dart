import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tapem/app_router.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/features/coaching/application/coaching_providers.dart';
import 'package:tapem/features/coaching/domain/models/coach_client_relation.dart';
import 'package:tapem/features/coaching/domain/models/client_coaching_analytics.dart';
import 'package:tapem/features/training_plan/application/training_plan_provider.dart';
import 'package:tapem/features/training_plan/application/plan_builder_provider.dart';
import 'package:tapem/features/training_plan/presentation/widgets/training_day_action_sheet.dart';
import 'package:tapem/features/training_plan/presentation/widgets/plan_selection_sheet.dart';
import 'package:tapem/features/training_plan/domain/models/training_plan.dart';
import 'package:tapem/core/widgets/brand_interactive_card.dart';
import 'package:tapem/features/profile/presentation/widgets/calendar_popup.dart';
import 'package:tapem/features/friends/providers/friends_riverpod.dart';

class CoachingClientDetailScreen extends ConsumerWidget {
  const CoachingClientDetailScreen({super.key, required this.relation});

  final CoachClientRelation relation;

  String _formatDateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _openClientTrainingSchedule(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final clientId = relation.clientId;

    // Trainingsdaten des Clients laden (Kalender-Heatmap).
    final friendCalendarNotifier = ref.read(friendCalendarProvider.notifier);
    await friendCalendarNotifier.setActiveFriend(clientId);
    final friendCalendarState = ref.read(friendCalendarProvider);
    final trainingDates = friendCalendarState.trainingDates;
    final gymIdsByDate = friendCalendarState.gymIdsByDate;

    if (!context.mounted) return;

    final selected = await showDialog<DateTime>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => CalendarPopup(
        trainingDates: trainingDates,
        initialYear: DateTime.now().year,
        userId: clientId,
        navigateOnTap: false,
        gymIdsByDate: gymIdsByDate,
      ),
    );

    if (!context.mounted || selected == null) {
      return;
    }

    final dateKey = _formatDateKey(selected);
    final gymIdForDay = gymIdsByDate[dateKey] ?? relation.gymId;

    String? assignedPlanName;
    String? assignedPlanId;
    try {
      final scheduleRepo = ref.read(trainingScheduleRepositoryProvider);
      final assignment = await scheduleRepo.getAssignment(
        userId: clientId,
        dateKey: dateKey,
      );
      if (assignment != null) {
        assignedPlanId = assignment.planId;
        final planRepo = ref.read(trainingPlanRepositoryProvider);
        final plans = await planRepo.getPlans(
          gymId: gymIdForDay,
          userId: clientId,
        );
        final matching = plans.where((p) => p.id == assignment.planId);
        if (matching.isNotEmpty) {
          assignedPlanName = matching.first.name;
        }
      }
    } catch (_) {
      assignedPlanName = null;
    }

    if (!context.mounted) return;

    showModalBottomSheet<void>(
      context: context,
      builder: (_) => TrainingDayActionSheet(
        date: selected,
        assignedPlanName: assignedPlanName,
        onOpenDetails: () {
          final args = <String, dynamic>{
            'userId': clientId,
            'date': selected,
          };
          if (gymIdForDay.isNotEmpty) {
            args['gymId'] = gymIdForDay;
          }
          Navigator.of(context).pushNamed(
            AppRouter.trainingDetails,
            arguments: args,
          );
        },
        onOpenPlanSelection: () async {
          if (gymIdForDay.isEmpty) {
            return;
          }
          try {
            final planRepo = ref.read(trainingPlanRepositoryProvider);
            final plans = await planRepo.getPlans(
              gymId: gymIdForDay,
              userId: clientId,
            );
            if (!context.mounted) return;
            showModalBottomSheet<void>(
              context: context,
              builder: (_) => PlanSelectionSheet(
                plans: plans,
                currentUserId: clientId,
                selectedPlanId: assignedPlanId,
                onClear: assignedPlanId == null
                    ? null
                    : () async {
                        final scheduleRepo =
                            ref.read(trainingScheduleRepositoryProvider);
                        await scheduleRepo.clearAssignment(
                          userId: clientId,
                          dateKey: dateKey,
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Plan-Zuweisung für diesen Tag für ${relation.clientId} entfernt.',
                            ),
                          ),
                        );
                      },
                onSelect: (plan) async {
                  final scheduleRepo =
                      ref.read(trainingScheduleRepositoryProvider);
                  await scheduleRepo.setAssignment(
                    userId: clientId,
                    dateKey: dateKey,
                    planId: plan.id,
                  );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Plan "${plan.name}" für diesen Tag für ${relation.clientId} geplant.',
                      ),
                    ),
                  );
                },
              ),
            );
          } catch (e) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Fehler beim Laden der Pläne: $e'),
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final brandColor = brandTheme?.outline ?? theme.colorScheme.secondary;

    final nameAsync =
        ref.watch(clientDisplayNameProvider(relation.clientId));

    final plansAsync = relation.isActive
        ? ref.watch(clientTrainingPlansProvider(relation.clientId))
        : const AsyncValue.data(<TrainingPlan>[]);

    final analyticsAsync = relation.isActive
        ? ref.watch(clientCoachingAnalyticsProvider(relation.clientId))
        : AsyncValue<ClientCoachingAnalytics>.data(
            ClientCoachingAnalytics.empty(),
          );

    return Scaffold(
      appBar: AppBar(
        title: nameAsync.when(
          data: (name) => Text(
            name,
            style: TextStyle(color: brandColor),
          ),
          loading: () => Text(
            'Client',
            style: TextStyle(color: brandColor),
          ),
          error: (_, __) => Text(
            relation.clientId,
            style: TextStyle(color: brandColor),
          ),
        ),
        foregroundColor: brandColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ClientHeader(relation: relation),
            const SizedBox(height: AppSpacing.md),
            analyticsAsync.when(
              data: (analytics) => analytics.hasData
                  ? _ClientAnalyticsOverview(analytics: analytics)
                  : const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: AppSpacing.lg),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: relation.isActive
                    ? () {
                        ref
                            .read(planBuilderProvider.notifier)
                            .startNew(
                              targetUserId: relation.clientId,
                              coachId: relation.coachId,
                              coachingRelationId: relation.id,
                            );
                        Navigator.pushNamed(
                          context,
                          AppRouter.trainingPlanPicker,
                        );
                      }
                    : null,
                icon: const Icon(Icons.add),
                label: const Text('Plan für Client erstellen'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: relation.isActive
                    ? () => _openClientTrainingSchedule(context, ref)
                    : null,
                icon: const Icon(Icons.calendar_today_outlined),
                label: const Text('Trainingstage planen'),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: plansAsync.when(
                data: (plans) {
                  if (plans.isEmpty) {
                    return Center(
                      child: Text(
                        'Noch keine Trainingspläne vorhanden.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    );
                  }
                  final activePlans = plans;
                  return ListView(
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    children: [
                      Text(
                        'Trainingspläne',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      for (final plan in activePlans)
                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppSpacing.sm,
                          ),
                          child: _ClientPlanCard(
                            plan: plan,
                            clientId: relation.clientId,
                          ),
                        ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Progress-Überblick',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      for (final plan in activePlans)
                        _ClientPlanProgressRow(
                          plan: plan,
                          clientId: relation.clientId,
                        ),
                    ],
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: Text(
                    'Pläne konnten nicht geladen werden.\n$err',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClientHeader extends StatelessWidget {
  const _ClientHeader({required this.relation});

  final CoachClientRelation relation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          Icon(
            Icons.school_outlined,
            color: colorScheme.primary,
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                relation.isActive
                    ? 'Aktives Coaching'
                    : relation.isPending
                        ? 'Anfrage in Bearbeitung'
                        : relation.isEnded
                            ? 'Coaching beendet'
                            : relation.isRejected
                                ? 'Coaching abgelehnt'
                                : relation.status,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Gym-ID: ${relation.gymId}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ClientPlanCard extends ConsumerWidget {
  const _ClientPlanCard({
    required this.plan,
    required this.clientId,
  });

  final TrainingPlan plan;
  final String clientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final radius =
        (brandTheme?.radius ?? BorderRadius.circular(AppRadius.card))
            as BorderRadius;
    final onSurface = theme.colorScheme.onSurface;
    final brandColor = brandTheme?.outline ?? theme.colorScheme.secondary;

    final statsAsync = ref.watch(
      clientTrainingPlanStatsProvider(
        ClientPlanStatsKey(clientId: clientId, planId: plan.id),
      ),
    );

    return BrandInteractiveCard(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRouter.trainingPlanDetail,
          arguments: plan,
        );
      },
      borderRadius: radius,
      padding: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              brandColor.withOpacity(0.08),
              brandColor.withOpacity(0.02),
            ],
          ),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(AppRadius.card),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
                border: Border.all(
                  color: theme.colorScheme.onSurface.withOpacity(0.05),
                ),
              ),
              child: Icon(
                Icons.view_list_rounded,
                color: brandColor,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    plan.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: onSurface,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${plan.exercises.length} ${plan.exercises.length == 1 ? 'Übung' : 'Übungen'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: statsAsync.when(
                          data: (stats) => Text(
                            stats.completions == 0
                                ? 'Noch nicht abgeschlossen'
                                : '${stats.completions}x abgeschlossen',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: onSurface.withOpacity(0.6),
                            ),
                          ),
                          loading: () => Text(
                            'Lade Stats …',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: onSurface.withOpacity(0.4),
                            ),
                          ),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: onSurface.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                color: brandColor,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClientAnalyticsOverview extends StatelessWidget {
  const _ClientAnalyticsOverview({required this.analytics});

  final ClientCoachingAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final lastActivityText = analytics.lastActivity != null
        ? 'Letzte Aktivität: '
            '${_formatDate(analytics.lastActivity!)}'
        : 'Noch keine abgeschlossenen Einheiten';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.7),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Überblick',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'Abschlüsse gesamt',
                  value: analytics.totalCompletions.toString(),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _MetricTile(
                  label: 'Ø/Woche',
                  value:
                      analytics.avgSessionsPerWeek.toStringAsFixed(1),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            lastActivityText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final d = date.toLocal();
    final two = (int v) => v.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)}.${d.year}';
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.background.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientPlanProgressRow extends ConsumerWidget {
  const _ClientPlanProgressRow({
    required this.plan,
    required this.clientId,
  });

  final TrainingPlan plan;
  final String clientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statsAsync = ref.watch(
      clientTrainingPlanStatsProvider(
        ClientPlanStatsKey(clientId: clientId, planId: plan.id),
      ),
    );

    return statsAsync.when(
      data: (stats) {
        final completions = stats.completions;
        if (completions == 0) {
          return ListTile(
            dense: true,
            title: Text(plan.name),
            subtitle: const Text('Noch keine Abschlüsse'),
          );
        }
        final now = DateTime.now();
        final firstUse = stats.firstCompletedAt ?? now;
        final totalDays = now.difference(firstUse).inDays;
        final weeksSpan = (totalDays ~/ 7) + 1;
        final perWeek =
            weeksSpan > 0 ? completions / weeksSpan : completions.toDouble();

        return ListTile(
          dense: true,
          title: Text(plan.name),
          subtitle: Text(
            '$completions× abgeschlossen · Ø ${perWeek.toStringAsFixed(1)} pro Woche',
          ),
          leading: Icon(
            Icons.show_chart,
            color: theme.colorScheme.primary,
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

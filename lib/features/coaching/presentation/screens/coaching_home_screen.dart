import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/widgets/brand_interactive_card.dart';
import 'package:tapem/features/coaching/application/coaching_providers.dart';
import 'package:tapem/features/coaching/domain/models/coach_client_relation.dart';
import 'package:tapem/features/training_plan/application/training_plan_provider.dart';
import 'package:tapem/features/training_plan/domain/models/training_plan.dart';
import 'coaching_client_detail_screen.dart';
import 'package:tapem/features/coaching/application/coach_invite_providers.dart';
import 'package:tapem/features/coaching/presentation/screens/external_coach_invites_screen.dart';

class CoachingHomeScreen extends ConsumerStatefulWidget {
  const CoachingHomeScreen({super.key});

  @override
  ConsumerState<CoachingHomeScreen> createState() => _CoachingHomeScreenState();
}

class _CoachingHomeScreenState extends ConsumerState<CoachingHomeScreen> {
  String _searchQuery = '';
  String _statusFilter = 'all'; // all, active, pending

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final brandColor = brandTheme?.outline ?? theme.colorScheme.secondary;

    final relationsAsync = ref.watch(coachRelationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Coaching',
          style: TextStyle(color: brandColor),
        ),
        foregroundColor: brandColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.mail_outline),
            tooltip: 'Einladungen',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ExternalCoachInvitesScreen(),
                ),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(72),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Clients suchen …',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.trim().toLowerCase();
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ChoiceChip(
                      label: const Text('Alle'),
                      selected: _statusFilter == 'all',
                      onSelected: (_) {
                        setState(() {
                          _statusFilter = 'all';
                        });
                      },
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    ChoiceChip(
                      label: const Text('Aktiv'),
                      selected: _statusFilter == 'active',
                      onSelected: (_) {
                        setState(() {
                          _statusFilter = 'active';
                        });
                      },
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    ChoiceChip(
                      label: const Text('Anfragen'),
                      selected: _statusFilter == 'pending',
                      onSelected: (_) {
                        setState(() {
                          _statusFilter = 'pending';
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: relationsAsync.when(
        data: (relations) {
          // ignore: avoid_print
          print(
            '[CoachingHome] data loaded count=${relations.length} '
            'search="$_searchQuery" statusFilter=$_statusFilter',
          );
          if (relations.isEmpty) {
            return _EmptyState(color: brandColor);
          }

          var filtered = relations;
          if (_statusFilter == 'active') {
            filtered = filtered.where((r) => r.isActive).toList();
          } else if (_statusFilter == 'pending') {
            filtered = filtered.where((r) => r.isPending).toList();
          }

          final active = filtered.where((r) => r.isActive).toList();
          final pending = filtered.where((r) => r.isPending).toList();
          final others = filtered
              .where((r) => !r.isActive && !r.isPending)
              .toList();
          final ordered = [...active, ...pending, ...others];

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: ordered.length,
            itemBuilder: (context, index) {
              final relation = ordered[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _CoachClientCard(
                  relation: relation,
                  searchQuery: _searchQuery,
                ),
              );
            },
          );
        },
        loading: () {
          // ignore: avoid_print
          print('[CoachingHome] loading relations…');
          return const Center(child: CircularProgressIndicator());
        },
        error: (err, _) {
          // ignore: avoid_print
          print('[CoachingHome] ERROR loading relations -> $err');
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                'Coaching-Daten konnten nicht geladen werden.\n$err',
                textAlign: TextAlign.center,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 64,
              color: color.withOpacity(0.6),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Noch keine Coaching-Clients',
              style: theme.textTheme.titleMedium?.copyWith(
                color: color.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Sobald Mitglieder dich als Coach auswählen\noder Einladungen annehmen, erscheinen sie hier.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _CoachClientCard extends ConsumerWidget {
  const _CoachClientCard({
    required this.relation,
    required this.searchQuery,
  });

  final CoachClientRelation relation;
  final String searchQuery;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final radius =
        (brandTheme?.radius ?? BorderRadius.circular(AppRadius.card))
            as BorderRadius;
    final onSurface = theme.colorScheme.onSurface;
    final brandColor = brandTheme?.outline ?? theme.colorScheme.secondary;

    final nameAsync =
        ref.watch(clientDisplayNameProvider(relation.clientId));
    final plansAsync =
        ref.watch(clientTrainingPlansProvider(relation.clientId));

    return nameAsync.when(
      data: (name) {
        if (searchQuery.isNotEmpty &&
            !name.toLowerCase().contains(searchQuery)) {
          return const SizedBox.shrink();
        }
        return _buildCard(context, ref, name, theme, radius, onSurface,
            brandColor, plansAsync);
      },
      loading: () => _buildCard(
        context,
        ref,
        null,
        theme,
        radius,
        onSurface,
        brandColor,
        plansAsync,
      ),
      error: (_, __) => _buildCard(
        context,
        ref,
        relation.clientId,
        theme,
        radius,
        onSurface,
        brandColor,
        plansAsync,
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    WidgetRef ref,
    String? name,
    ThemeData theme,
    BorderRadius radius,
    Color onSurface,
    Color brandColor,
    AsyncValue<List<TrainingPlan>> plansAsync,
  ) {
    return BrandInteractiveCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CoachingClientDetailScreen(relation: relation),
          ),
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(AppRadius.card),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: theme.colorScheme.onSurface.withOpacity(0.05),
                ),
              ),
              child: Icon(
                Icons.person_outline,
                color: brandColor,
                size: 26,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (name == null)
                    const SizedBox(
                      height: 16,
                      width: 80,
                      child: LinearProgressIndicator(),
                    )
                  else
                    Text(
                      name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: onSurface,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.4,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _StatusChip(relation: relation),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: plansAsync.when(
                          data: (plans) => _PlanCountChip(plans: plans),
                          loading: () => Text(
                            'Lade Pläne …',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: onSurface.withOpacity(0.6),
                            ),
                          ),
                          error: (_, __) => Text(
                            'Pläne nicht verfügbar',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (relation.isPending || relation.isActive)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: Row(
                        children: [
                          if (relation.isPending) ...[
                            TextButton.icon(
                              onPressed: () async {
                                final repo =
                                    ref.read(coachingRepositoryProvider);
                                try {
                                  await repo.updateRelationStatus(
                                    relationId: relation.id,
                                    status: 'active',
                                  );
                                  ref.invalidate(coachRelationsProvider);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Coaching-Anfrage angenommen'),
                                    ),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Fehler beim Annehmen: $e',
                                      ),
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.check),
                              label: const Text('Annehmen'),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            TextButton.icon(
                              onPressed: () async {
                                final repo =
                                    ref.read(coachingRepositoryProvider);
                                try {
                                  await repo.updateRelationStatus(
                                    relationId: relation.id,
                                    status: 'rejected',
                                  );
                                  ref.invalidate(coachRelationsProvider);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Coaching-Anfrage abgelehnt'),
                                    ),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Fehler beim Ablehnen: $e',
                                      ),
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.close),
                              label: const Text('Ablehnen'),
                              style: TextButton.styleFrom(
                                foregroundColor: theme.colorScheme.error,
                              ),
                            ),
                          ],
                          if (relation.isActive)
                            TextButton.icon(
                              onPressed: () async {
                                final confirmed =
                                    await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text(
                                              'Coaching beenden?',
                                            ),
                                            content: const Text(
                                              'Diese Coaching-Beziehung wird beendet. '
                                              'Trainingsdaten bleiben beim Mitglied erhalten.',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(ctx, false),
                                                child:
                                                    const Text('Abbrechen'),
                                              ),
                                              FilledButton(
                                                onPressed: () =>
                                                    Navigator.pop(ctx, true),
                                                child:
                                                    const Text('Beenden'),
                                              ),
                                            ],
                                          ),
                                        ) ??
                                        false;
                                if (!confirmed) return;
                                final repo =
                                    ref.read(coachingRepositoryProvider);
                                try {
                                  await repo.updateRelationStatus(
                                    relationId: relation.id,
                                    status: 'ended',
                                  );
                                  ref.invalidate(coachRelationsProvider);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Coaching beendet'),
                                    ),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Fehler beim Beenden: $e',
                                      ),
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.stop_circle_outlined),
                              label: const Text('Coaching beenden'),
                            ),
                        ],
                      ),
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

class _PlanCountChip extends StatelessWidget {
  const _PlanCountChip({required this.plans});

  final List<TrainingPlan> plans;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final count = plans.length;
    final label =
        count == 0 ? 'Keine Pläne' : '$count ${count == 1 ? 'Plan' : 'Pläne'}';
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: onSurface.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: onSurface.withOpacity(0.7),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.relation});

  final CoachClientRelation relation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    late final String label;
    late final Color bg;
    late final Color fg;

    if (relation.isActive) {
      label = 'Aktiv';
      bg = colorScheme.primary.withOpacity(0.12);
      fg = colorScheme.primary;
    } else if (relation.isPending) {
      label = 'Anfrage offen';
      bg = colorScheme.tertiary.withOpacity(0.12);
      fg = colorScheme.tertiary;
    } else if (relation.isEnded) {
      label = 'Beendet';
      bg = colorScheme.outline.withOpacity(0.08);
      fg = colorScheme.outline;
    } else if (relation.isRejected) {
      label = 'Abgelehnt';
      bg = colorScheme.error.withOpacity(0.08);
      fg = colorScheme.error;
    } else {
      label = relation.status;
      bg = colorScheme.surfaceVariant;
      fg = colorScheme.onSurfaceVariant;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

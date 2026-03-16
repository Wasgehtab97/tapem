import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/widgets/app_error_card.dart';
import 'package:tapem/core/widgets/app_loading_indicator.dart';
import 'package:tapem/core/widgets/brand_modal.dart';
import 'package:tapem/core/widgets/brand_primary_button.dart';
import 'package:tapem/core/widgets/premium_action_tile.dart';
import 'package:tapem/features/training_plan/domain/models/training_plan.dart';
import 'package:tapem/features/training_plan/presentation/widgets/plan_color_palette.dart';
import 'package:tapem/features/training_plan/application/plan_builder_provider.dart';
import 'package:tapem/features/training_plan/application/training_plan_provider.dart';

class PlanOverviewScreen extends ConsumerStatefulWidget {
  const PlanOverviewScreen({super.key, this.onExitToProfile});

  final VoidCallback? onExitToProfile;

  @override
  ConsumerState<PlanOverviewScreen> createState() => _PlanOverviewScreenState();
}

class _PlanOverviewScreenState extends ConsumerState<PlanOverviewScreen> {
  List<String>? _localPlanOrderIds;
  bool _isPersistingOrder = false;

  void _handleBackPressed(BuildContext context) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    widget.onExitToProfile?.call();
  }

  Widget? _buildLeadingBackButton(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    if (!canPop && widget.onExitToProfile == null) {
      return null;
    }
    return IconButton(
      onPressed: () => _handleBackPressed(context),
      icon: const Icon(Icons.chevron_left_rounded),
    );
  }

  List<TrainingPlan> _resolveDisplayPlans(List<TrainingPlan> remotePlans) {
    final localOrderIds = _localPlanOrderIds;
    if (localOrderIds == null) {
      return remotePlans;
    }
    if (localOrderIds.length != remotePlans.length) {
      return remotePlans;
    }

    final plansById = <String, TrainingPlan>{
      for (final plan in remotePlans) plan.id: plan,
    };
    if (localOrderIds.any((id) => !plansById.containsKey(id))) {
      return remotePlans;
    }

    return <TrainingPlan>[for (final id in localOrderIds) plansById[id]!];
  }

  Future<void> _persistPlanOrder({
    required String userId,
    required List<String> reorderedIds,
    required List<String> previousIds,
  }) async {
    if (_isPersistingOrder) return;
    setState(() => _isPersistingOrder = true);
    try {
      await ref
          .read(trainingPlanRepositoryProvider)
          .reorderPlans(userId: userId, orderedPlanIds: reorderedIds);
      if (!mounted) return;
      ref.invalidate(trainingPlansProvider);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _localPlanOrderIds = previousIds;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reihenfolge konnte nicht gespeichert werden: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isPersistingOrder = false);
      }
    }
  }

  Future<void> _handlePlanReorder({
    required int oldIndex,
    required int newIndex,
    required List<TrainingPlan> displayPlans,
    required String userId,
  }) async {
    if (_isPersistingOrder) {
      return;
    }
    if (oldIndex < 0 || oldIndex >= displayPlans.length) {
      return;
    }
    var targetIndex = newIndex;
    if (oldIndex < targetIndex) {
      targetIndex -= 1;
    }
    if (targetIndex < 0 || targetIndex >= displayPlans.length) {
      targetIndex = targetIndex.clamp(0, displayPlans.length - 1);
    }
    if (oldIndex == targetIndex) {
      return;
    }

    final reordered = List<TrainingPlan>.from(displayPlans);
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(targetIndex, moved);

    final previousIds = displayPlans.map((plan) => plan.id).toList();
    final reorderedIds = reordered.map((plan) => plan.id).toList();

    setState(() {
      _localPlanOrderIds = reorderedIds;
    });

    await _persistPlanOrder(
      userId: userId,
      reorderedIds: reorderedIds,
      previousIds: previousIds,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final brandColor = brandTheme?.outline ?? theme.colorScheme.secondary;

    final plansAsync = ref.watch(trainingPlansProvider);
    final authState = ref.watch(authViewStateProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        leading: _buildLeadingBackButton(context),
        title: Text(
          'Trainingspläne',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        foregroundColor: brandColor,
      ),
      body: plansAsync.when(
        data: (plans) {
          if (plans.isEmpty) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 80, 20, 24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          brandColor.withOpacity(0.18),
                          Colors.black.withOpacity(0.6),
                        ],
                      ),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.35),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                brandColor.withOpacity(0.6),
                                brandColor.withOpacity(0.08),
                              ],
                            ),
                          ),
                          child: const Icon(
                            Icons.assignment_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Dein erster Plan wartet',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Erstelle einen Trainingsplan und bring Struktur in dein Workout.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 18),
                        FilledButton.icon(
                          onPressed: () => _createNewPlan(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Ersten Plan erstellen'),
                          style: FilledButton.styleFrom(
                            backgroundColor: brandColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            textStyle: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Pläne helfen dir dabei, konsistent Fortschritte zu tracken.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      letterSpacing: 0.4,
                      color: Colors.white.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            );
          }
          final userId = authState.userId;
          final displayPlans = _resolveDisplayPlans(plans);
          return Stack(
            children: [
              ReorderableListView.builder(
                itemCount: displayPlans.length,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                buildDefaultDragHandles: false,
                onReorder: (oldIndex, newIndex) async {
                  if (userId == null || userId.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Reihenfolge kann aktuell nicht geändert werden.',
                        ),
                      ),
                    );
                    return;
                  }
                  await _handlePlanReorder(
                    oldIndex: oldIndex,
                    newIndex: newIndex,
                    displayPlans: displayPlans,
                    userId: userId,
                  );
                },
                itemBuilder: (context, index) {
                  final plan = displayPlans[index];
                  final isCoachPlan =
                      plan.coachId != null && plan.coachId != authState.userId;
                  return ReorderableDelayedDragStartListener(
                    key: ValueKey(plan.id),
                    index: index,
                    enabled: !_isPersistingOrder,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _PlanCard(
                        name: plan.name,
                        exerciseCount: plan.exercises.length,
                        isCoachPlan: isCoachPlan,
                        colorIndex: plan.colorIndex,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRouter.trainingPlanDetail,
                            arguments: plan,
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
              if (_isPersistingOrder)
                const Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: LinearProgressIndicator(minHeight: 2),
                ),
            ],
          );
        },
        loading: () => const AppLoadingIndicator(),
        error: (err, stack) => AppErrorCard(
          message: 'Fehler beim Laden der Pläne:\n$err',
          onRetry: () => ref.invalidate(trainingPlansProvider),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createNewPlan(context),
        backgroundColor: brandColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Future<void> _createNewPlan(BuildContext context) async {
    final name = await showDialog<String>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => const _CreatePlanDialog(),
    );

    if (name != null && name.isNotEmpty) {
      if (!context.mounted) return;

      // Initialize Builder Logic
      ref.read(planBuilderProvider.notifier).startNew();
      ref.read(planBuilderProvider.notifier).updateName(name);

      // Navigate to Exercise Picker (Modified Gym Screen)
      Navigator.pushNamed(context, AppRouter.trainingPlanPicker);
    }
  }
}

class _CreatePlanDialog extends StatefulWidget {
  const _CreatePlanDialog();

  @override
  State<_CreatePlanDialog> createState() => _CreatePlanDialogState();
}

class _CreatePlanDialogState extends State<_CreatePlanDialog> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final brandColor = brandTheme?.outline ?? theme.colorScheme.secondary;
    final canCreate = _nameController.text.trim().isNotEmpty;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: BrandModalSurface(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BrandModalHeader(
              icon: Icons.assignment_rounded,
              accent: brandColor,
              title: 'Neuer Trainingsplan',
              subtitle: 'Gib deinem Plan einen Namen',
              onClose: () => Navigator.pop(context),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _nameController,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) {
                final value = _nameController.text.trim();
                if (value.isEmpty) return;
                Navigator.pop(context, value);
              },
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Name (z.B. Push Day)',
                filled: true,
                fillColor: Colors.white.withOpacity(0.04),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: brandColor.withOpacity(0.4),
                    width: 1.2,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: Colors.white.withOpacity(0.08),
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: brandColor.withOpacity(0.9),
                    width: 1.4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Abbrechen'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: BrandPrimaryButton(
                    onPressed: canCreate
                        ? () => Navigator.pop(
                            context,
                            _nameController.text.trim(),
                          )
                        : null,
                    child: const Text(
                      'Erstellen',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.name,
    required this.exerciseCount,
    this.isCoachPlan = false,
    required this.colorIndex,
    required this.onTap,
  });

  final String name;
  final int exerciseCount;
  final bool isCoachPlan;
  final int colorIndex;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tileAccent =
        theme.extension<AppBrandTheme>()?.outline ??
        theme.colorScheme.secondary;
    final arrowColor = PlanColorPalette.colorForIndex(colorIndex, theme);
    final subtitle = StringBuffer(
      '$exerciseCount ${exerciseCount == 1 ? 'Übung' : 'Übungen'}',
    );
    if (isCoachPlan) {
      subtitle.write(' · Coach-Plan');
    }

    return PremiumActionTile(
      onTap: onTap,
      leading: const Icon(Icons.view_list_rounded, size: 20),
      title: name,
      subtitle: subtitle.toString(),
      accentColor: tileAccent,
      trailingColor: arrowColor,
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 10,
      ),
    );
  }
}

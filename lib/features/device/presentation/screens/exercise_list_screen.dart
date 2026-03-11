import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;

import 'package:tapem/app_router.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/core/providers/muscle_group_provider.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/widgets/brand_gradient_icon.dart';
import 'package:tapem/core/widgets/brand_modal.dart';
import 'package:tapem/core/widgets/brand_primary_button.dart';
import 'package:tapem/core/widgets/premium_action_tile.dart';
import 'package:tapem/features/device/domain/models/exercise.dart';
import 'package:tapem/features/device/presentation/models/workout_device_selection.dart';
import 'package:tapem/features/device/presentation/widgets/exercise_bottom_sheet.dart';
import 'package:tapem/features/muscle_group/domain/models/muscle_group.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/ui/muscles/muscle_group_display.dart';
import 'package:tapem/core/services/workout_session_coordinator.dart';
import 'package:tapem/features/device/presentation/controllers/workout_day_controller.dart';
import 'package:tapem/features/device/providers/exercise_provider.dart';
import 'package:tapem/features/device/providers/workout_entry_orchestrator_provider.dart';
import 'package:tapem/features/device/providers/workout_day_controller_provider.dart';

class ExerciseListScreen extends riverpod.ConsumerStatefulWidget {
  final String gymId;
  final String deviceId;
  final ValueChanged<WorkoutDeviceSelection>? onSelect;

  const ExerciseListScreen({
    super.key,
    required this.gymId,
    required this.deviceId,
    this.onSelect,
  });

  @override
  riverpod.ConsumerState<ExerciseListScreen> createState() =>
      _ExerciseListScreenState();
}

class _ExerciseListScreenState
    extends riverpod.ConsumerState<ExerciseListScreen> {
  final _searchCtr = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    final userId = riverpod.ProviderScope.containerOf(
      context,
      listen: false,
    ).read(authControllerProvider).userId!;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final container = riverpod.ProviderScope.containerOf(context);
      container
          .read(exerciseProvider)
          .loadExercises(widget.gymId, widget.deviceId, userId);
      container.read(muscleGroupProvider).loadGroups(context);
    });
  }

  @override
  void dispose() {
    _searchCtr.dispose();
    super.dispose();
  }

  Future<void> _openAdd([Exercise? ex]) async {
    final result = await showDialog<Exercise>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => ExerciseBottomSheet(
        gymId: widget.gymId,
        deviceId: widget.deviceId,
        exercise: ex,
      ),
    );
    if (result != null && ex == null && mounted) {
      final selection = WorkoutDeviceSelection(
        gymId: widget.gymId,
        deviceId: widget.deviceId,
        exerciseId: result.id,
        exerciseName: result.name,
      );
      final onSelect = widget.onSelect;
      if (onSelect != null) {
        onSelect(selection);
      } else {
        final container = riverpod.ProviderScope.containerOf(context);
        final coordinator = container.read(workoutSessionCoordinatorProvider);
        if (coordinator.isRunning) {
          final auth = container.read(authControllerProvider);
          final userId = auth.userId;
          if (userId != null) {
            try {
              final orchestrator = container.read(
                workoutEntryOrchestratorProvider,
              );
              final controller = container.read(workoutDayControllerProvider);
              await orchestrator.addOrFocusFromExternalSource(
                controller: controller,
                coordinator: coordinator,
                gymId: widget.gymId,
                deviceId: widget.deviceId,
                exerciseId: result.id,
                exerciseName: result.name,
                userId: userId,
              );
            } catch (_) {
              // Fallback
            }
          }
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRouter.home,
            (route) => false,
            arguments: 2,
          );
        } else {
          Navigator.of(context).pushNamed(
            AppRouter.workoutDay,
            arguments: {
              'gymId': widget.gymId,
              'deviceId': widget.deviceId,
              'exerciseId': result.id,
              'entryRequestedAtMs': DateTime.now().millisecondsSinceEpoch,
            },
          );
        }
      }
    }
  }

  Future<void> _deleteExercise(Exercise ex) async {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final brand = theme.extension<AppBrandTheme>();
    final brandColor = brand?.outline ?? theme.colorScheme.secondary;
    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: BrandModalSurface(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BrandModalHeader(
                icon: Icons.delete_outline_rounded,
                accent: brandColor,
                title: loc.exerciseDeleteTitle,
                subtitle: loc.exerciseDeleteMessage(ex.name),
                onClose: () => Navigator.of(ctx).pop(false),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: Text(loc.commonCancel),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: BrandPrimaryButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: Text(loc.commonDelete),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirm != true) return;
    final container = riverpod.ProviderScope.containerOf(context);
    final userId = container.read(authControllerProvider).userId!;
    await container
        .read(exerciseProvider)
        .removeExercise(widget.gymId, widget.deviceId, ex.id, userId);
  }

  List<Exercise> _filteredExercises(List<Exercise> all) {
    final q = _query.trim().toLowerCase();
    final filtered = all
        .where((ex) => ex.name.toLowerCase().contains(q))
        .toList();
    filtered.sort((a, b) => a.name.compareTo(b.name));
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final brand = theme.extension<AppBrandTheme>();
    final brandColor = brand?.outline ?? theme.colorScheme.secondary;

    final prov = ref.watch(exerciseProvider);
    final muscleGroups = ref.watch(
      muscleGroupProvider.select((provider) => provider.groups),
    );
    final exercises = _filteredExercises(prov.exercises);

    Widget body;
    if (prov.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (prov.error != null) {
      body = Center(
        child: Text(
          '${loc.errorPrefix}: ${prov.error}',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
      );
    } else if (exercises.isEmpty) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off,
                size: 48,
                color: brandColor.withOpacity(0.7),
              ),
              const SizedBox(height: 12),
              Text(
                loc.multiDeviceNoExercises,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(color: brandColor),
              ),
              const SizedBox(height: 16),
              Text(
                loc.multiDeviceNewExercise,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      body = ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        itemCount: exercises.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (_, i) {
          final ex = exercises[i];
          return _ExerciseCard(
            exercise: ex,
            muscleGroups: muscleGroups,
            onOpen: () async {
              final selection = WorkoutDeviceSelection(
                gymId: widget.gymId,
                deviceId: widget.deviceId,
                exerciseId: ex.id,
                exerciseName: ex.name,
              );
              final onSelect = widget.onSelect;
              if (onSelect != null) {
                onSelect(selection);
              } else {
                final container = riverpod.ProviderScope.containerOf(context);
                final coordinator = container.read(
                  workoutSessionCoordinatorProvider,
                );
                if (coordinator.isRunning) {
                  final auth = container.read(authControllerProvider);
                  final userId = auth.userId;
                  if (userId != null) {
                    try {
                      final orchestrator = container.read(
                        workoutEntryOrchestratorProvider,
                      );
                      final controller = container.read(
                        workoutDayControllerProvider,
                      );
                      await orchestrator.addOrFocusFromExternalSource(
                        controller: controller,
                        coordinator: coordinator,
                        gymId: widget.gymId,
                        deviceId: widget.deviceId,
                        exerciseId: ex.id,
                        exerciseName: ex.name,
                        userId: userId,
                      );
                    } catch (_) {
                      // Fallback
                    }
                  }
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRouter.home,
                    (route) => false,
                    arguments: 2,
                  );
                } else {
                  Navigator.of(context).pushNamed(
                    AppRouter.workoutDay,
                    arguments: {
                      'gymId': widget.gymId,
                      'deviceId': widget.deviceId,
                      'exerciseId': ex.id,
                      'entryRequestedAtMs':
                          DateTime.now().millisecondsSinceEpoch,
                    },
                  );
                }
              }
            },
            onEdit: () => _openAdd(ex),
            onDelete: () => _deleteExercise(ex),
            editLabel: loc.multiDeviceEditExerciseButton,
            deleteLabel: loc.exerciseDeleteTitle,
          );
        },
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  _ExerciseBackButton(
                    color: brandColor,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      loc.multiDeviceExerciseListTitle,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: brandColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: TextField(
                controller: _searchCtr,
                decoration: InputDecoration(
                  hintText: loc.multiDeviceSearchHint,
                  prefixIcon: const BrandGradientIcon(Icons.search),
                  filled: true,
                  fillColor: theme.colorScheme.surface.withOpacity(0.32),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: brandColor.withOpacity(0.75),
                      width: 1.2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
                onChanged: (value) => setState(() => _query = value),
                textInputAction: TextInputAction.search,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: body,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: PremiumActionTile(
                onTap: () => _openAdd(),
                leading: const Icon(Icons.add_rounded, size: 20),
                title: loc.multiDeviceNewExercise,
                subtitle: 'Neue Übung für dieses Gerät erstellen',
                accentColor: brandColor,
                margin: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final Exercise exercise;
  final List<MuscleGroup> muscleGroups;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final String editLabel;
  final String deleteLabel;

  const _ExerciseCard({
    required this.exercise,
    required this.muscleGroups,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
    required this.editLabel,
    required this.deleteLabel,
  });

  String? _muscleSummary() {
    final byId = <String, MuscleGroup>{
      for (final group in muscleGroups) group.id: group,
    };
    final ids = [
      ...exercise.primaryMuscleGroupIds,
      ...exercise.secondaryMuscleGroupIds,
    ];
    final labels = <String>[];
    final seenLabels = <String>{};

    void addLabel(String value) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return;
      final normalized = trimmed.toLowerCase();
      if (seenLabels.add(normalized)) {
        labels.add(trimmed);
      }
    }

    for (final rawId in ids) {
      final group = byId[rawId];
      if (group != null) {
        addLabel(displayNameForMuscleGroup(group.region, group));
        continue;
      }

      for (final region in MuscleRegion.values) {
        if (region.name == rawId) {
          addLabel(displayNameForMuscleGroup(region, null));
          break;
        }
      }
    }

    // Legacy fallback: ältere Datensätze können die Gruppen nur indirekt
    // über group.exerciseIds referenzieren.
    if (labels.isEmpty) {
      for (final group in muscleGroups) {
        if (!group.exerciseIds.contains(exercise.id)) continue;
        addLabel(displayNameForMuscleGroup(group.region, group));
      }
    }

    if (labels.isEmpty) return null;
    return labels.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandColor =
        theme.extension<AppBrandTheme>()?.outline ??
        theme.colorScheme.secondary;

    return PremiumActionTile(
      onTap: onOpen,
      leading: const Icon(Icons.fitness_center_rounded, size: 20),
      title: exercise.name,
      subtitle: _muscleSummary(),
      accentColor: brandColor,
      trailingLeading: PopupMenuButton<_ExerciseAction>(
        tooltip: editLabel,
        icon: Icon(
          Icons.more_vert_rounded,
          color: theme.colorScheme.onSurface.withOpacity(0.72),
        ),
        onSelected: (value) {
          if (value == _ExerciseAction.edit) {
            onEdit();
            return;
          }
          onDelete();
        },
        itemBuilder: (_) => [
          PopupMenuItem<_ExerciseAction>(
            value: _ExerciseAction.edit,
            child: Row(
              children: [
                const Icon(Icons.edit_outlined, size: 18),
                const SizedBox(width: 8),
                Text(editLabel),
              ],
            ),
          ),
          PopupMenuItem<_ExerciseAction>(
            value: _ExerciseAction.delete,
            child: Row(
              children: [
                Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: 8),
                Text(
                  deleteLabel,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _ExerciseAction { edit, delete }

class _ExerciseBackButton extends StatelessWidget {
  const _ExerciseBackButton({required this.onPressed, required this.color});

  final VoidCallback onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.36),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Icon(Icons.arrow_back_rounded, color: color),
        ),
      ),
    );
  }
}

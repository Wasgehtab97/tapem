import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tapem/app_router.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/features/device/providers/exercise_provider.dart';
import 'package:tapem/core/providers/muscle_group_provider.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/widgets/brand_gradient_icon.dart';
import 'package:tapem/core/widgets/brand_interactive_card.dart';
import 'package:tapem/core/widgets/brand_outline_button.dart';
import 'package:tapem/core/widgets/brand_primary_button.dart';
import 'package:tapem/features/device/domain/models/exercise.dart';
import 'package:tapem/features/device/presentation/models/workout_device_selection.dart';
import 'package:tapem/features/device/presentation/widgets/exercise_bottom_sheet.dart';
import 'package:tapem/features/device/presentation/widgets/muscle_chips.dart';
import 'package:tapem/features/muscle_group/domain/models/muscle_group.dart';
import 'package:tapem/l10n/app_localizations.dart';

class ExerciseListScreen extends StatefulWidget {
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
  State<ExerciseListScreen> createState() => _ExerciseListScreenState();
}

class _ExerciseListScreenState extends State<ExerciseListScreen> {
  final _searchCtr = TextEditingController();
  String _query = '';
  final Set<String> _selectedGroups = {};
  bool _sortDescending = false;

  @override
  void initState() {
    super.initState();
    final userId = context.read<AuthProvider>().userId!;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExerciseProvider>().loadExercises(widget.gymId, widget.deviceId, userId);
      context.read<MuscleGroupProvider>().loadGroups(context);
    });
  }

  @override
  void dispose() {
    _searchCtr.dispose();
    super.dispose();
  }

  Future<void> _openAdd([Exercise? ex]) async {
    final result = await showModalBottomSheet<Exercise>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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
      );
      final onSelect = widget.onSelect;
      if (onSelect != null) {
        onSelect(selection);
      } else {
        Navigator.of(context).pushReplacementNamed(
          AppRouter.workoutDay,
          arguments: {
            'gymId': widget.gymId,
            'deviceId': widget.deviceId,
            'exerciseId': result.id,
          },
        );
      }
    }
  }

  Future<void> _deleteExercise(Exercise ex) async {
    final loc = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.exerciseDeleteTitle),
        content: Text(loc.exerciseDeleteMessage(ex.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(loc.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(loc.commonDelete),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final userId = context.read<AuthProvider>().userId!;
    await context
        .read<ExerciseProvider>()
        .removeExercise(widget.gymId, widget.deviceId, ex.id, userId);
  }

  Future<void> _openMuscleFilter(List<MuscleGroup> groups) async {
    final loc = AppLocalizations.of(context)!;
    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      builder: (ctx) {
        final selected = Set<String>.from(_selectedGroups);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: StatefulBuilder(
              builder: (context, setSt) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.filterMuscleChip,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final g in groups)
                        FilterChip(
                          label: Text(g.name),
                          selected: selected.contains(g.id),
                          onSelected: (value) {
                            setSt(() {
                              if (value) {
                                selected.add(g.id);
                              } else {
                                selected.remove(g.id);
                              }
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      if (selected.isNotEmpty)
                        TextButton(
                          onPressed: () => setSt(() => selected.clear()),
                          child: Text(loc.multiDeviceMuscleGroupFilterAll),
                        ),
                      const Spacer(),
                      BrandPrimaryButton(
                        onPressed: () => Navigator.of(ctx).pop(selected),
                        child: Text(loc.commonOk),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (result != null) {
      setState(() {
        _selectedGroups
          ..clear()
          ..addAll(result);
      });
    }
  }

  List<Exercise> _filteredExercises(List<Exercise> all) {
    final q = _query.trim().toLowerCase();
    final filtered = all.where((ex) {
      final matchesQuery = ex.name.toLowerCase().contains(q);
      final matchesGroup = _selectedGroups.isEmpty ||
          _selectedGroups.any((id) => ex.muscleGroupIds.contains(id));
      return matchesQuery && matchesGroup;
    }).toList();
    filtered.sort((a, b) =>
        _sortDescending ? b.name.compareTo(a.name) : a.name.compareTo(b.name));
    return filtered;
  }

  String _groupName(String id, List<MuscleGroup> groups) {
    return groups.firstWhereOrNull((g) => g.id == id)?.name ?? id;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final brand = theme.extension<AppBrandTheme>();
    final brandColor = brand?.outline ?? theme.colorScheme.secondary;

    final prov = context.watch<ExerciseProvider>();
    final groups = context.watch<MuscleGroupProvider>().groups;

    final exercises = _filteredExercises(prov.exercises);

    Widget body;
    if (prov.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (prov.error != null) {
      body = Center(
        child: Text(
          '${loc.errorPrefix}: ${prov.error}',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
        ),
      );
    } else if (exercises.isEmpty) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off, size: 48, color: brandColor.withOpacity(0.7)),
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
            onOpen: () {
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
                Navigator.of(context).pushNamed(
                  AppRouter.workoutDay,
                  arguments: {
                    'gymId': widget.gymId,
                    'deviceId': widget.deviceId,
                    'exerciseId': ex.id,
                  },
                );
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
                  BrandOutlineButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                    child: const Icon(Icons.arrow_back),
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
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
                onChanged: (value) => setState(() => _query = value),
                textInputAction: TextInputAction.search,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  FilterChip(
                    label: Text(
                      loc.filterNameChip,
                      style: theme.textTheme.labelLarge?.copyWith(
                            color: brandColor,
                          ) ??
                          TextStyle(color: brandColor),
                    ),
                    selected: _sortDescending,
                    onSelected: (_) => setState(() => _sortDescending = !_sortDescending),
                    shape: const StadiumBorder(),
                    selectedColor: theme.colorScheme.primaryContainer,
                    showCheckmark: false,
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: Text(
                      loc.filterMuscleChip,
                      style: theme.textTheme.labelLarge?.copyWith(
                            color: brandColor,
                          ) ??
                          TextStyle(color: brandColor),
                    ),
                    selected: _selectedGroups.isNotEmpty,
                    onSelected: (_) => _openMuscleFilter(groups),
                    shape: const StadiumBorder(),
                    selectedColor: theme.colorScheme.primaryContainer,
                    showCheckmark: false,
                  ),
                ],
              ),
            ),
            if (_selectedGroups.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final id in _selectedGroups)
                      InputChip(
                        label: Text(_groupName(id, groups)),
                        onDeleted: () => setState(() => _selectedGroups.remove(id)),
                      ),
                  ],
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
              child: BrandPrimaryButton(
                onPressed: () => _openAdd(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add),
                    const SizedBox(width: 8),
                    Text(loc.multiDeviceNewExercise),
                  ],
                ),
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
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final String editLabel;
  final String deleteLabel;

  const _ExerciseCard({
    required this.exercise,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
    required this.editLabel,
    required this.deleteLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandColor = theme.extension<AppBrandTheme>()?.outline ?? theme.colorScheme.secondary;
    final secondaryColor = theme.colorScheme.onSurface.withOpacity(0.7);

    return BrandInteractiveCard(
      onTap: onOpen,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: brandColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                MuscleChips(
                  primaryIds: exercise.primaryMuscleGroupIds,
                  secondaryIds: exercise.secondaryMuscleGroupIds,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                color: secondaryColor,
                tooltip: editLabel,
                onPressed: onEdit,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                color: theme.colorScheme.error,
                tooltip: deleteLabel,
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

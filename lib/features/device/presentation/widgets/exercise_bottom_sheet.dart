import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;

import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/core/providers/muscle_group_provider.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/widgets/brand_outline_button.dart';
import 'package:tapem/core/widgets/brand_primary_button.dart';
import 'package:tapem/features/device/domain/models/exercise.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/ui/muscles/muscle_group_list_selector.dart';
import 'package:tapem/features/device/presentation/widgets/muscle_chips.dart';
import 'package:tapem/features/device/providers/exercise_provider.dart';

class ExerciseBottomSheet extends StatefulWidget {
  final String gymId;
  final String deviceId;
  final Exercise? exercise;

  const ExerciseBottomSheet({
    super.key,
    required this.gymId,
    required this.deviceId,
    this.exercise,
  });

  @override
  State<ExerciseBottomSheet> createState() => _ExerciseBottomSheetState();
}

class _ExerciseBottomSheetState extends State<ExerciseBottomSheet> {
  late TextEditingController _nameCtr;
  late TextEditingController _searchCtr;
  List<String> _primaryIds = [];
  List<String> _secondaryIds = [];
  late List<String> _initialPrimary;
  late List<String> _initialSecondary;
  String _filter = '';
  bool _isSaving = false;

  bool get _hasChanges =>
      _nameCtr.text.trim() != (widget.exercise?.name ?? '') ||
      !listEquals(_primaryIds, _initialPrimary) ||
      !listEquals(_secondaryIds, _initialSecondary);

  Future<bool> _confirmDiscard() async {
    if (!_hasChanges) return true;
    final loc = AppLocalizations.of(context)!;
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.exerciseEdit_discardChangesTitle),
        content: Text(loc.exerciseEdit_discardChangesMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(loc.exerciseEdit_keepEditing),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(loc.exerciseEdit_discard),
          ),
        ],
      ),
    );
    return res ?? false;
  }

  @override
  void initState() {
    super.initState();
    _nameCtr = TextEditingController(text: widget.exercise?.name ?? '');
    _searchCtr = TextEditingController();
    _primaryIds = List.of(widget.exercise?.primaryMuscleGroupIds ?? const []);
    _secondaryIds = List.of(
      widget.exercise?.secondaryMuscleGroupIds ?? const [],
    );
    _initialPrimary = List.of(_primaryIds);
    _initialSecondary = List.of(_secondaryIds);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prov = riverpod.ProviderScope.containerOf(context, listen: false)
          .read(muscleGroupProvider);
      await prov.loadGroups(context);
      if (!mounted) return;
      final normalizedPrimary = prov.canonicalizeGroupIds(_primaryIds);
      final normalizedSecondary = prov
          .canonicalizeGroupIds(_secondaryIds)
          .where((id) => !normalizedPrimary.contains(id))
          .toList();
      setState(() {
        _primaryIds = normalizedPrimary.isEmpty
            ? const []
            : [normalizedPrimary.first];
        _secondaryIds = normalizedSecondary;
        _initialPrimary = List.of(_primaryIds);
        _initialSecondary = List.of(_secondaryIds);
      });
    });
  }

  @override
  void dispose() {
    _nameCtr.dispose();
    _searchCtr.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;
    final name = _nameCtr.text.trim();
    if (name.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    final container = riverpod.ProviderScope.containerOf(context, listen: false);
    final auth = container.read(authControllerProvider);
    final userId = auth.userId!;
    final exProv = container.read(exerciseProvider);
    final muscleProv = container.read(muscleGroupProvider);
    final loc = AppLocalizations.of(context)!;

    final normalizedPrimary = muscleProv.canonicalizeGroupIds(_primaryIds);
    final primaryIds = normalizedPrimary.isEmpty
        ? const <String>[]
        : [normalizedPrimary.first];
    final secondaryIds = muscleProv
        .canonicalizeGroupIds(_secondaryIds)
        .where((id) => !primaryIds.contains(id))
        .toList();
    final shouldReassign = widget.exercise != null &&
        (!listEquals(primaryIds, _initialPrimary) ||
            !listEquals(secondaryIds, _initialSecondary));

    var shouldClose = false;
    try {
      Exercise ex;
      if (widget.exercise == null) {
        ex = await exProv.addExercise(
          widget.gymId,
          widget.deviceId,
          name,
          userId,
          primaryMuscleGroupIds: primaryIds,
          secondaryMuscleGroupIds: secondaryIds,
        );
      } else {
        await exProv.updateExercise(
          widget.gymId,
          widget.deviceId,
          widget.exercise!.id,
          name,
          userId,
          primaryMuscleGroupIds: primaryIds,
          secondaryMuscleGroupIds: secondaryIds,
        );
        ex = widget.exercise!.copyWith(
          name: name,
          primaryMuscleGroupIds: primaryIds,
          secondaryMuscleGroupIds: secondaryIds,
        );
      }
      await muscleProv.updateExerciseAssignments(
        context,
        ex.id,
        primaryIds,
        secondaryIds,
      );
      if (shouldReassign) {
        await exProv.reassignMuscleXp(
          widget.gymId,
          widget.deviceId,
          widget.exercise!.id,
          userId,
          primaryIds,
          secondaryIds,
        );
      }
      shouldClose = true;
      if (!mounted) return;
      Navigator.pop(context, ex);
    } on FirebaseException catch (e) {
      if (!mounted) return;
      final message = e.code == 'permission-denied'
          ? loc.commonSaveError
          : (e.message ?? loc.commonSaveError);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.commonSaveError)),
      );
    } finally {
      if (!shouldClose && mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final canSave =
        _nameCtr.text.trim().isNotEmpty && (widget.exercise == null || _hasChanges);

    return WillPopScope(
      onWillPop: _confirmDiscard,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SafeArea(
          top: false,
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 24,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.exercise == null
                        ? loc.exerciseAddTitle
                        : loc.exerciseEditTitle,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.extension<AppBrandTheme>()?.outline ??
                          theme.colorScheme.secondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nameCtr,
                    decoration: InputDecoration(
                      labelText: loc.exerciseNameLabel,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    autofocus: true,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    loc.exerciseMuscleGroupsLabel,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchCtr,
                    decoration: InputDecoration(
                      hintText: loc.exerciseSearchMuscleGroupsHint,
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onChanged: (v) => setState(() => _filter = v),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 320,
                    child: MuscleGroupListSelector(
                      initialPrimary: _initialPrimary,
                      initialSecondary: _initialSecondary,
                      onChanged: (p, s) => setState(() {
                        _primaryIds = p;
                        _secondaryIds = s;
                      }),
                      filter: _filter,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_primaryIds.isNotEmpty || _secondaryIds.isNotEmpty) ...[
                    Text(
                      loc.exerciseSelectedMuscleGroups,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: MuscleChips(
                        primaryIds: _primaryIds,
                        secondaryIds: _secondaryIds,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: BrandOutlineButton(
                          onPressed: _isSaving
                              ? null
                              : () async {
                                  if (await _confirmDiscard()) {
                                    if (mounted) Navigator.pop(context);
                                  }
                                },
                          child: Text(loc.commonCancel),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: BrandPrimaryButton(
                          onPressed: canSave && !_isSaving ? _save : null,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: _isSaving
                                ? const SizedBox(
                                    key: ValueKey('saving'),
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Row(
                                    key: const ValueKey('label'),
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.check),
                                      const SizedBox(width: 8),
                                      Text(loc.commonSave),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ],
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

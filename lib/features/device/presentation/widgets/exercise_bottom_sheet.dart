import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;

import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/core/providers/muscle_group_provider.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/widgets/brand_modal.dart';
import 'package:tapem/core/widgets/brand_primary_button.dart';
import 'package:tapem/features/device/domain/models/exercise.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/ui/muscles/muscle_group_list_selector.dart';
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

  String get _title {
    final loc = AppLocalizations.of(context)!;
    return widget.exercise == null
        ? loc.multiDeviceAddExerciseTitle
        : loc.multiDeviceEditExerciseTitle;
  }

  bool get _hasChanges =>
      _nameCtr.text.trim() != (widget.exercise?.name ?? '') ||
      !listEquals(_primaryIds, _initialPrimary) ||
      !listEquals(_secondaryIds, _initialSecondary);

  Future<bool> _confirmDiscard() async {
    if (!_hasChanges) return true;
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final brand = theme.extension<AppBrandTheme>();
    final brandColor = brand?.outline ?? theme.colorScheme.secondary;
    final res = await showDialog<bool>(
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
                icon: Icons.warning_amber_rounded,
                accent: brandColor,
                title: loc.exerciseEdit_discardChangesTitle,
                subtitle: loc.exerciseEdit_discardChangesMessage,
                onClose: () => Navigator.pop(ctx, false),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(loc.exerciseEdit_keepEditing),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: BrandPrimaryButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(loc.exerciseEdit_discard),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
      final prov = riverpod.ProviderScope.containerOf(
        context,
        listen: false,
      ).read(muscleGroupProvider);
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

  Future<void> _requestClose() async {
    if (await _confirmDiscard()) {
      if (mounted) {
        Navigator.pop(context);
      }
    }
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

    final container = riverpod.ProviderScope.containerOf(
      context,
      listen: false,
    );
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
    final shouldReassign =
        widget.exercise != null &&
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(loc.commonSaveError)));
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
    final mediaQuery = MediaQuery.of(context);
    final brand = theme.extension<AppBrandTheme>();
    final brandColor = brand?.outline ?? theme.colorScheme.secondary;
    final canSave =
        _nameCtr.text.trim().isNotEmpty &&
        (widget.exercise == null || _hasChanges);
    final height = mediaQuery.size.height;
    final visibleHeight = (height - mediaQuery.viewInsets.bottom).clamp(
      300.0,
      height,
    );
    final selectorHeight = (visibleHeight * 0.28).clamp(170.0, 340.0);
    final maxDialogHeight = (height - 40).clamp(280.0, height);

    return WillPopScope(
      onWillPop: _confirmDiscard,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxDialogHeight),
          child: BrandModalSurface(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.24),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  BrandModalHeader(
                    icon: widget.exercise == null
                        ? Icons.add_circle_outline_rounded
                        : Icons.edit_note_rounded,
                    accent: brandColor,
                    title: _title,
                    subtitle: 'Name und Muskelgruppen festlegen',
                    onClose: _isSaving ? null : _requestClose,
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _nameCtr,
                    decoration: InputDecoration(
                      labelText: loc.exerciseNameLabel,
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
                    autofocus: true,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    loc.exerciseMuscleGroupsLabel,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _searchCtr,
                    decoration: InputDecoration(
                      hintText: loc.exerciseSearchMuscleGroupsHint,
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: brandColor.withOpacity(0.9),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.03),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.18),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.18),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: brandColor.withOpacity(0.75),
                          width: 1.2,
                        ),
                      ),
                    ),
                    onChanged: (v) => setState(() => _filter = v),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: SizedBox(
                      height: selectorHeight,
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
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: _isSaving ? null : _requestClose,
                          child: Text(loc.commonCancel),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextButton(
                          onPressed: canSave && !_isSaving ? _save : null,
                          child: Text(loc.commonSave),
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

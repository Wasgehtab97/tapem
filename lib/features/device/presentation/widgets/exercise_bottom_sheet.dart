import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/exercise_provider.dart';
import 'package:tapem/core/providers/muscle_group_provider.dart';
import 'package:tapem/features/device/domain/models/exercise.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/ui/muscles/muscle_group_list_selector.dart';

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
    _secondaryIds =
        List.of(widget.exercise?.secondaryMuscleGroupIds ?? const []);
    _initialPrimary = List.of(_primaryIds);
    _initialSecondary = List.of(_secondaryIds);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MuscleGroupProvider>().loadGroups(context);
    });
  }

  @override
  void dispose() {
    _nameCtr.dispose();
    _searchCtr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final auth = context.read<AuthProvider>();
    final userId = auth.userId!;
    final hasChanges = _hasChanges;
    final canSave =
        _nameCtr.text.trim().isNotEmpty &&
            (widget.exercise == null || hasChanges);

    return WillPopScope(
      onWillPop: _confirmDiscard,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              widget.exercise == null
                  ? loc.exerciseAddTitle
                  : loc.exerciseEditTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _nameCtr,
              decoration: InputDecoration(labelText: loc.exerciseNameLabel),
              onChanged: (_) => setState(() {}),
              autofocus: true,
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              loc.exerciseMuscleGroupsLabel,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchCtr,
              decoration: InputDecoration(
                hintText: loc.exerciseSearchMuscleGroupsHint,
              ),
              onChanged: (v) => setState(() => _filter = v),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 300,
            child: MuscleGroupListSelector(
              initialPrimary: _initialPrimary,
              initialSecondary: _initialSecondary,
              onChanged: (p, s) =>
                  setState(() {
                    _primaryIds = p;
                    _secondaryIds = s;
                  }),
              filter: _filter,
            ),
          ),
          Row(
            children: [
              const SizedBox(width: 16),
              TextButton(
                onPressed: () async {
                  if (await _confirmDiscard()) {
                    if (context.mounted) Navigator.pop(context);
                  }
                },
                child: Text(loc.commonCancel),
              ),
              const Spacer(),
              TextButton(
                onPressed: canSave
                    ? () async {
                        final name = _nameCtr.text.trim();
                        final exProv = context.read<ExerciseProvider>();
                        Exercise ex;
                        if (widget.exercise == null) {
                          ex = await exProv.addExercise(
                            widget.gymId,
                            widget.deviceId,
                            name,
                            userId,
                            primaryMuscleGroupIds: _primaryIds,
                            secondaryMuscleGroupIds: _secondaryIds,
                          );
                        } else {
                          await exProv.updateExercise(
                            widget.gymId,
                            widget.deviceId,
                            widget.exercise!.id,
                            name,
                            userId,
                            primaryMuscleGroupIds: _primaryIds,
                            secondaryMuscleGroupIds: _secondaryIds,
                          );
                          ex = widget.exercise!.copyWith(
                            name: name,
                            primaryMuscleGroupIds: _primaryIds,
                            secondaryMuscleGroupIds: _secondaryIds,
                          );
                        }
                        await context
                            .read<MuscleGroupProvider>()
                            .updateExerciseAssignments(
                              context,
                              ex.id,
                              _primaryIds,
                              _secondaryIds,
                            );
                        if (!mounted) return;
                        Navigator.pop(context, ex);
                      }
                    : null,
                child: Text(loc.commonSave),
              ),
              const SizedBox(width: 16),
            ],
          ),
        ],
      ),
    );
  }
}

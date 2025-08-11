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
  List<String> _selectedGroupIds = [];
  String _filter = '';

  @override
  void initState() {
    super.initState();
    _nameCtr = TextEditingController(text: widget.exercise?.name ?? '');
    _searchCtr = TextEditingController();
    _selectedGroupIds.addAll(widget.exercise?.muscleGroupIds ?? const []);
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
    final canSave =
        _nameCtr.text.trim().isNotEmpty && _selectedGroupIds.isNotEmpty;

    return Padding(
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
          const SizedBox(height: 8),
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
          const SizedBox(height: 8),
          SizedBox(
            height: 280,
            child: MuscleGroupListSelector(
              initialSelection: _selectedGroupIds,
              onChanged: (ids) => setState(() => _selectedGroupIds = ids),
              filter: _filter,
            ),
          ),
          Row(
            children: [
              const SizedBox(width: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
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
                            muscleGroupIds: _selectedGroupIds,
                          );
                        } else {
                          await exProv.updateExercise(
                            widget.gymId,
                            widget.deviceId,
                            widget.exercise!.id,
                            name,
                            userId,
                            muscleGroupIds: _selectedGroupIds,
                          );
                          ex = widget.exercise!.copyWith(
                            name: name,
                            muscleGroupIds: _selectedGroupIds,
                          );
                        }
                        await context
                            .read<MuscleGroupProvider>()
                            .assignExercise(
                              context,
                              ex.id,
                              _selectedGroupIds,
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

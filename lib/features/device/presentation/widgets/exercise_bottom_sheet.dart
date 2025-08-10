import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/exercise_provider.dart';
import 'package:tapem/core/providers/muscle_group_provider.dart';
import 'package:tapem/features/device/domain/models/exercise.dart';
import 'package:tapem/l10n/app_localizations.dart';

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
  final Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    _nameCtr = TextEditingController(text: widget.exercise?.name ?? '');
    _selected.addAll(widget.exercise?.muscleGroupIds ?? const []);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MuscleGroupProvider>().loadGroups(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final groups = context.watch<MuscleGroupProvider>().groups;
    final auth = context.read<AuthProvider>();
    final userId = auth.userId!;

    final canSave =
        _nameCtr.text.trim().isNotEmpty && _selected.isNotEmpty;

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
                  ? loc.multiDeviceAddExerciseTitle
                  : loc.multiDeviceEditExerciseTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _nameCtr,
              decoration:
                  InputDecoration(labelText: loc.multiDeviceNameFieldLabel),
              onChanged: (_) => setState(() {}),
              autofocus: true,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(loc.multiDeviceMuscleGroupSection,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (final g in groups)
                  FilterChip(
                    label: Text(g.name),
                    selected: _selected.contains(g.id),
                    onSelected: (v) => setState(() {
                      if (v) {
                        _selected.add(g.id);
                      } else {
                        _selected.remove(g.id);
                      }
                    }),
                  ),
              ],
            ),
          ),
          Row(
            children: [
              const SizedBox(width: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(loc.multiDeviceCancel),
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
                            muscleGroupIds: _selected.toList(),
                          );
                        } else {
                          await exProv.updateExercise(
                            widget.gymId,
                            widget.deviceId,
                            widget.exercise!.id,
                            name,
                            userId,
                            muscleGroupIds: _selected.toList(),
                          );
                          ex = widget.exercise!.copyWith(
                            name: name,
                            muscleGroupIds: _selected.toList(),
                          );
                        }
                        await context
                            .read<MuscleGroupProvider>()
                            .assignExercise(
                              context,
                              ex.id,
                              _selected.toList(),
                            );
                        if (!mounted) return;
                        Navigator.pop(context, ex);
                      }
                    : null,
                child: Text(loc.multiDeviceSave),
              ),
              const SizedBox(width: 16),
            ],
          ),
        ],
      ),
    );
  }
}

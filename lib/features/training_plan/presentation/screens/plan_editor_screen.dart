import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/training_plan_provider.dart';
import '../../domain/models/exercise_entry.dart';
import '../../domain/models/split_day.dart';
import '../widgets/device_selection_dialog.dart';
import 'package:tapem/ui/numeric_keypad/overlay_numeric_keypad.dart';
import 'package:tapem/l10n/app_localizations.dart';

class PlanEditorScreen extends StatelessWidget {
  const PlanEditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<TrainingPlanProvider>();
    final plan = prov.currentPlan!;

    return DefaultTabController(
      length: plan.days.length,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          appBar: AppBar(
            title: Text(plan.name),
            actions: [
              IconButton(
                icon: prov.isSaving
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                tooltip: 'Speichern',
                onPressed: prov.isSaving
                    ? null
                    : () async {
                        final loc = AppLocalizations.of(context)!;
                        final gymId = context.read<AuthProvider>().gymCode;
                        if (gymId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(loc.invalidGymSelectionError)),
                          );
                          return;
                        }
                        await prov.saveCurrentPlan(gymId);
                        if (context.mounted) {
                          final msg = prov.error ?? 'Plan gespeichert';
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text(msg)));
                        }
                      },
              ),
            ],
            bottom: TabBar(
              isScrollable: true,
              tabs: [
                for (var day in plan.days)
                  Tab(text: 'Tag ${day.index + 1}${day.name != null ? ' - ${day.name}' : ''}')
              ],
            ),
          ),
          body: TabBarView(
            children: [
              for (var i = 0; i < plan.days.length; i++)
                _DayView(dayIndex: i, day: plan.days[i])
            ],
          ),
        ),
      ),
    );
  }
}

class _DayView extends StatelessWidget {
  final int dayIndex;
  final SplitDay day;

  const _DayView({
    required this.dayIndex,
    required this.day,
  });

  @override
  Widget build(BuildContext context) {
    final prov = context.read<TrainingPlanProvider>();
    return ListView.builder(
      itemCount: day.exercises.length + 2,
      itemBuilder: (context, index) {
        if (index == 0) {
          return ListTile(
            title: Text('Tag ${dayIndex + 1}${day.name != null ? ' - ${day.name}' : ''}'),
          );
        }
        if (index == day.exercises.length + 1) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: OutlinedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Übung hinzufügen'),
              onPressed: () async {
                final base = ExerciseEntry(
                  deviceId: '',
                  exerciseId: '',
                  exerciseName: '',
                  setType: '',
                  totalSets: 0,
                  workSets: 0,
                  reps: 0,
                  restInSeconds: 0,
                );
                final entry = await showDeviceSelectionDialog(context, base);
                if (entry != null) {
                  prov.addExercise(dayIndex, entry);
                }
              },
            ),
          );
        }
        final ex = day.exercises[index - 1];
        final exIndex = index - 1;
        return Dismissible(
          key: ValueKey('day-$dayIndex-$exIndex'),
          background: Container(color: Theme.of(context).colorScheme.error),
          onDismissed: (_) => prov.removeExercise(dayIndex, exIndex),
          child: _PlanEntryEditor(
            entry: ex,
            onChanged: (updated) =>
                prov.updateExercise(dayIndex, exIndex, updated),
            onSelectDevice: () async {
              final updated = await showDeviceSelectionDialog(context, ex);
              if (updated != null) {
                prov.updateExercise(dayIndex, exIndex, updated);
              }
            },
          ),
        );
      },
    );
  }
}

class _PlanEntryEditor extends StatefulWidget {
  final ExerciseEntry entry;
  final ValueChanged<ExerciseEntry> onChanged;
  final VoidCallback onSelectDevice;

  const _PlanEntryEditor({
    required this.entry,
    required this.onChanged,
    required this.onSelectDevice,
  });

  @override
  State<_PlanEntryEditor> createState() => _PlanEntryEditorState();
}

class _PlanEntryEditorState extends State<_PlanEntryEditor> {
  late TextEditingController _setsCtr;
  late TextEditingController _repsCtr;

  @override
  void initState() {
    super.initState();
    _setsCtr = TextEditingController(text: widget.entry.workSets.toString());
    _repsCtr = TextEditingController(text: widget.entry.reps?.toString() ?? '');
  }

  @override
  void dispose() {
    _setsCtr.dispose();
    _repsCtr.dispose();
    super.dispose();
  }

  void _emitUpdate() {
    widget.onChanged(
      ExerciseEntry(
        deviceId: widget.entry.deviceId,
        exerciseId: widget.entry.exerciseId,
        exerciseName: widget.entry.exerciseName,
        setType: widget.entry.setType,
        totalSets: int.tryParse(_setsCtr.text) ?? 0,
        workSets: int.tryParse(_setsCtr.text) ?? 0,
        reps: int.tryParse(_repsCtr.text),
        weight: widget.entry.weight,
        restInSeconds: widget.entry.restInSeconds,
        notes: widget.entry.notes,
        sets: widget.entry.sets,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.entry.exerciseName.isNotEmpty
                        ? widget.entry.exerciseName
                        : widget.entry.exerciseId,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: widget.onSelectDevice,
                  icon: const Icon(Icons.edit),
                  tooltip: 'Gerät ändern',
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _setsCtr,
                    decoration: const InputDecoration(
                      labelText: 'Arbeitssätze',
                      isDense: true,
                    ),
                    readOnly: true,
                    keyboardType: TextInputType.none,
                    onTap: () => context
                        .read<OverlayNumericKeypadController>()
                        .openFor(_setsCtr, allowDecimal: false),
                    onChanged: (_) => _emitUpdate(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _repsCtr,
                    decoration: const InputDecoration(
                      labelText: 'Wdh',
                      isDense: true,
                    ),
                    readOnly: true,
                    keyboardType: TextInputType.none,
                    onTap: () => context
                        .read<OverlayNumericKeypadController>()
                        .openFor(_repsCtr, allowDecimal: false),
                    onChanged: (_) => _emitUpdate(),
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

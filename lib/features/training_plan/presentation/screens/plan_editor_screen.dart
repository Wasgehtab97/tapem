import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/device_provider.dart';
import '../../../../core/providers/exercise_provider.dart';
import '../../../../core/providers/training_plan_provider.dart';
import '../../../device/domain/models/device.dart';
import '../../../device/domain/models/exercise.dart';
import 'package:intl/intl.dart';
import '../../domain/models/exercise_entry.dart';
import '../../domain/models/week_block.dart';
import '../widgets/device_selection_dialog.dart';

class PlanEditorScreen extends StatefulWidget {
  const PlanEditorScreen({super.key});

  @override
  State<PlanEditorScreen> createState() => _PlanEditorScreenState();
}

class _PlanEditorScreenState extends State<PlanEditorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _weekController;

  @override
  void initState() {
    super.initState();
    final plan = context.read<TrainingPlanProvider>().currentPlan!;
    _weekController = TabController(length: plan.weeks.length, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<TrainingPlanProvider>();
    final plan = prov.currentPlan!;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(plan.name),
          actions: [
            IconButton(
              icon:
                  prov.isSaving
                      ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.check),
              tooltip: 'Speichern',
              onPressed:
                  prov.isSaving
                      ? null
                      : () async {
                        final gymId = context.read<AuthProvider>().gymCode!;
                        await prov.saveCurrentPlan(gymId);
                        if (context.mounted) {
                          final msg = prov.error ?? 'Plan gespeichert';
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(msg)));
                        }
                      },
            ),
            IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: plan.startDate,
                  firstDate: DateTime.now().subtract(
                    const Duration(days: 365 * 5),
                  ),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                );
                if (picked != null) {
                  final monday = picked.subtract(
                    Duration(days: picked.weekday - 1),
                  );
                  prov.setStartDate(monday);
                }
              },
            ),
          ],
          bottom: TabBar(
            controller: _weekController,
            isScrollable: true,
            tabs: [
              for (var w in plan.weeks) Tab(text: 'Woche ${w.weekNumber}'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _weekController,
          children: [for (var w in plan.weeks) _WeekView(week: w)],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            final week = plan.weeks[_weekController.index].weekNumber;
            final day = await _pickDay(
              context,
              plan.weeks[_weekController.index],
            );
            if (day == null) return;
            final base = ExerciseEntry(
              deviceId: '',
              exerciseId: '',
              exerciseName: '',
              setType: '',
              totalSets: 0,
              workSets: 0,
              reps: 0,
              rir: 0,
              restInSeconds: 0,
            );
            final entry = await showDeviceSelectionDialog(context, base);
            if (entry != null) {
              prov.addExercise(week, day, entry);
            }
          },
          label: const Text('Übung hinzufügen'),
          icon: const Icon(Icons.add),
        ),
      ),
    );
  }

  Future<DateTime?> _pickDay(BuildContext context, WeekBlock week) async {
    if (week.days.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte zuerst einen Tag hinzufügen')),
      );
      return null;
    }
    return showDialog<DateTime>(
      context: context,
      builder:
          (_) => SimpleDialog(
            title: const Text('Trainingstag wählen'),
            children: [
              for (var d in week.days)
                SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, d.date),
                  child: Text(DateFormat.yMd().add_E().format(d.date)),
                ),
            ],
          ),
    );
  }
}

class _WeekView extends StatefulWidget {
  final WeekBlock week;
  const _WeekView({required this.week});

  @override
  State<_WeekView> createState() => _WeekViewState();
}

class _WeekViewState extends State<_WeekView>
    with SingleTickerProviderStateMixin {
  late TabController _dayController;

  @override
  void initState() {
    super.initState();
    _dayController = TabController(length: 7, vsync: this);
  }

  @override
  void didUpdateWidget(covariant _WeekView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.week.days.length != widget.week.days.length) {
      _dayController.dispose();
      _dayController = TabController(length: 7, vsync: this);
      setState(() {});
    }
  }

  @override
  void dispose() {
    _dayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.read<TrainingPlanProvider>();
    final weekNumber = widget.week.weekNumber;
    return Column(
      children: [
        TabBar(
          controller: _dayController,
          tabs: const [
            Tab(text: 'Mo'),
            Tab(text: 'Di'),
            Tab(text: 'Mi'),
            Tab(text: 'Do'),
            Tab(text: 'Fr'),
            Tab(text: 'Sa'),
            Tab(text: 'So'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _dayController,
            children: [
              for (var day in widget.week.days)
                ListView.builder(
                  itemCount: day.exercises.length,
                  itemBuilder: (context, index) {
                    final ex = day.exercises[index];
                    return Dismissible(
                      key: ValueKey('${day.date}-$index'),
                      background: Container(color: Colors.red),
                      onDismissed:
                          (_) =>
                              prov.removeExercise(weekNumber, day.date, index),
                      child: _PlanEntryEditor(
                        entry: ex,
                        onChanged:
                            (updated) => prov.updateExercise(
                              weekNumber,
                              day.date,
                              index,
                              updated,
                            ),
                        onSelectDevice: () async {
                          final updated = await showDeviceSelectionDialog(
                            context,
                            ex,
                          );
                          if (updated != null) {
                            prov.updateExercise(
                              weekNumber,
                              day.date,
                              index,
                              updated,
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
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
  late TextEditingController _rirCtr;

  @override
  void initState() {
    super.initState();
    _setsCtr = TextEditingController(text: widget.entry.workSets.toString());
    _repsCtr = TextEditingController(text: widget.entry.reps?.toString() ?? '');
    _rirCtr = TextEditingController(text: widget.entry.rir.toString());
  }

  @override
  void dispose() {
    _setsCtr.dispose();
    _repsCtr.dispose();
    _rirCtr.dispose();
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
        weight: null,
        rir: int.tryParse(_rirCtr.text) ?? 0,
        restInSeconds: widget.entry.restInSeconds,
        notes: null,
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
                    widget.entry.exerciseId,
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
                    keyboardType: TextInputType.number,
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
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _emitUpdate(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _rirCtr,
                    decoration: const InputDecoration(
                      labelText: 'RIR',
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
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

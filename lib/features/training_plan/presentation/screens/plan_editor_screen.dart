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
    return Scaffold(
      appBar: AppBar(
        title: Text(plan.name),
        bottom: TabBar(
          controller: _weekController,
          isScrollable: true,
          tabs: [for (var w in plan.weeks) Tab(text: 'Woche ${w.weekNumber}')],
        ),
      ),
      body: TabBarView(
        controller: _weekController,
        children: [for (var w in plan.weeks) _WeekView(week: w)],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
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
          child:
              prov.isSaving
                  ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text('Speichern'),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final week = plan.weeks[_weekController.index].weekNumber;
          final day = await _pickDay(context, plan.weeks[_weekController.index]);
          if (day == null) return;
          final base = ExerciseEntry(
            deviceId: '',
            exerciseId: '',
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
      builder: (_) => SimpleDialog(
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
    _dayController = TabController(
      length: widget.week.days.length,
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(covariant _WeekView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.week.days.length != widget.week.days.length) {
      _dayController.dispose();
      _dayController = TabController(
        length: widget.week.days.length,
        vsync: this,
      );
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
          Row(
            children: [
              Expanded(
                child: TabBar(
                  controller: _dayController,
                  tabs: [
                    for (var d in widget.week.days)
                      Tab(text: DateFormat.Md().add_E().format(d.date))
                  ],
                ),
              ),
              IconButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    prov.addDay(weekNumber, picked);
                  }
                },
                icon: const Icon(Icons.add),
                tooltip: 'Tag hinzufügen',
              ),
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
                      onDismissed: (_) =>
                          prov.removeExercise(weekNumber, day.date, index),
                      child: _PlanEntryEditor(
                        entry: ex,
                        onChanged: (updated) => prov.updateExercise(
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
  final List<TextEditingController> _weightCtrs = [];
  final List<TextEditingController> _repsCtrs = [];
  final List<TextEditingController> _rirCtrs = [];
  final List<TextEditingController> _noteCtrs = [];

  @override
  void initState() {
    super.initState();
    final initialSets = widget.entry.totalSets > 0 ? widget.entry.totalSets : 1;
    for (var i = 0; i < initialSets; i++) {
      _weightCtrs.add(TextEditingController(
          text: widget.entry.weight?.toString() ?? ''));
      _repsCtrs
          .add(TextEditingController(text: widget.entry.reps?.toString() ?? ''));
      _rirCtrs.add(TextEditingController(
          text: widget.entry.rir != 0 ? widget.entry.rir.toString() : ''));
      _noteCtrs
          .add(TextEditingController(text: widget.entry.notes ?? ''));
    }
  }

  @override
  void dispose() {
    for (final c in _weightCtrs) c.dispose();
    for (final c in _repsCtrs) c.dispose();
    for (final c in _rirCtrs) c.dispose();
    for (final c in _noteCtrs) c.dispose();
    super.dispose();
  }

  void _emitUpdate() {
    final weight = _weightCtrs.isNotEmpty ? _weightCtrs.first.text : '';
    final reps = _repsCtrs.isNotEmpty ? _repsCtrs.first.text : '';
    final rir = _rirCtrs.isNotEmpty ? _rirCtrs.first.text : '';
    final note = _noteCtrs.isNotEmpty ? _noteCtrs.first.text : '';

    widget.onChanged(
      ExerciseEntry(
        deviceId: widget.entry.deviceId,
        exerciseId: widget.entry.exerciseId,
        setType: widget.entry.setType,
        totalSets: _weightCtrs.length,
        workSets: _weightCtrs.length,
        weight: double.tryParse(weight),
        reps: int.tryParse(reps),
        rir: int.tryParse(rir) ?? 0,
        restInSeconds: widget.entry.restInSeconds,
        notes: note.isEmpty ? null : note,
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
            Table(
              columnWidths: const {
                0: IntrinsicColumnWidth(),
                1: FlexColumnWidth(),
                2: FlexColumnWidth(),
                3: IntrinsicColumnWidth(),
                4: FlexColumnWidth(),
              },
              children: [
                for (var i = 0; i < _weightCtrs.length; i++)
                  TableRow(children: [
                    Padding(
                      padding: const EdgeInsets.all(4),
                      child: Text('${i + 1}'),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(4),
                      child: TextFormField(
                        controller: _weightCtrs[i],
                        decoration: const InputDecoration(
                          labelText: 'kg',
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => _emitUpdate(),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(4),
                      child: TextFormField(
                        controller: _repsCtrs[i],
                        decoration: const InputDecoration(
                          labelText: 'x',
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => _emitUpdate(),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(4),
                      child: TextFormField(
                        controller: _rirCtrs[i],
                        decoration: const InputDecoration(
                          labelText: 'RIR',
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => _emitUpdate(),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(4),
                      child: TextFormField(
                        controller: _noteCtrs[i],
                        decoration: const InputDecoration(
                          labelText: 'Notiz',
                          isDense: true,
                        ),
                        onChanged: (_) => _emitUpdate(),
                      ),
                    ),
                  ]),
              ],
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () {
                  setState(() {
                    _weightCtrs.add(TextEditingController());
                    _repsCtrs.add(TextEditingController());
                    _rirCtrs.add(TextEditingController());
                    _noteCtrs.add(TextEditingController());
                  });
                  _emitUpdate();
                },
                icon: const Icon(Icons.add),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

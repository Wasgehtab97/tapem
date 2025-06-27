import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/device_provider.dart';
import '../../../../core/providers/exercise_provider.dart';
import '../../../../core/providers/training_plan_provider.dart';
import '../../../device/domain/models/device.dart';
import '../../../device/domain/models/exercise.dart';
import '../../domain/models/exercise_entry.dart';
import '../../domain/models/week_block.dart';

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
          final day = await _pickDay(context);
          if (day == null) return;
          final entry = await _editEntry(context);
          if (entry != null) {
            prov.addExercise(week, day, entry);
          }
        },
        label: const Text('Übung hinzufügen'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Future<String?> _pickDay(BuildContext context) async {
    return showDialog<String>(
      context: context,
      builder:
          (_) => SimpleDialog(
            title: const Text('Trainingstag wählen'),
            children: [
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, 'Mo'),
                child: const Text('Montag'),
              ),
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, 'Do'),
                child: const Text('Donnerstag'),
              ),
            ],
          ),
    );
  }

  Future<ExerciseEntry?> _editEntry(
    BuildContext context, {
    ExerciseEntry? entry,
  }) async {
    final gymId = context.read<AuthProvider>().gymCode!;
    final userId = context.read<AuthProvider>().userId!;
    await context.read<DeviceProvider>().loadDevices(gymId);
    final devices = context.read<DeviceProvider>().devices;
    Device? selectedDevice =
        entry == null
            ? null
            : devices.firstWhere(
              (d) => d.id == entry.deviceId,
              orElse: () => devices.isNotEmpty ? devices.first : null,
            );
    Exercise? selectedExercise;
    final setTypeCtr = TextEditingController(text: entry?.setType ?? '');
    final setsCtr = TextEditingController(
      text: entry?.totalSets.toString() ?? '',
    );
    final workCtr = TextEditingController(
      text: entry?.workSets.toString() ?? '',
    );
    final repsCtr = TextEditingController(text: entry?.reps.toString() ?? '');
    final rirCtr = TextEditingController(text: entry?.rir.toString() ?? '');
    final restCtr = TextEditingController(
      text: entry?.restInSeconds.toString() ?? '',
    );
    final notesCtr = TextEditingController(text: entry?.notes ?? '');

    return showDialog<ExerciseEntry>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(
              entry == null ? 'Übung hinzufügen' : 'Übung bearbeiten',
            ),
            content: StatefulBuilder(
              builder:
                  (ctx, setState) => SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButton<Device>(
                          value: selectedDevice,
                          hint: const Text('Gerät wählen'),
                          isExpanded: true,
                          items: [
                            for (var d in devices)
                              DropdownMenuItem(value: d, child: Text(d.name)),
                          ],
                          onChanged:
                              (d) => setState(() {
                                selectedDevice = d;
                                selectedExercise = null;
                              }),
                        ),
                        if (selectedDevice != null && selectedDevice!.isMulti)
                          FutureBuilder<List<Exercise>>(
                            future: context
                                .read<ExerciseProvider>()
                                .loadExercises(
                                  gymId,
                                  selectedDevice!.id,
                                  userId,
                                )
                                .then(
                                  (_) =>
                                      context
                                          .read<ExerciseProvider>()
                                          .exercises,
                                ),
                            builder: (context, snapshot) {
                              final exList = snapshot.data ?? [];
                              return DropdownButton<Exercise>(
                                value: selectedExercise,
                                hint: const Text('Übung wählen'),
                                isExpanded: true,
                                items: [
                                  for (var ex in exList)
                                    DropdownMenuItem(
                                      value: ex,
                                      child: Text(ex.name),
                                    ),
                                ],
                                onChanged:
                                    (e) => setState(() => selectedExercise = e),
                              );
                            },
                          ),
                        TextField(
                          controller: setTypeCtr,
                          decoration: const InputDecoration(
                            labelText: 'Satzart',
                          ),
                        ),
                        TextField(
                          controller: setsCtr,
                          decoration: const InputDecoration(
                            labelText: 'Gesamt-Sätze',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        TextField(
                          controller: workCtr,
                          decoration: const InputDecoration(
                            labelText: 'Arbeitssätze',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        TextField(
                          controller: repsCtr,
                          decoration: const InputDecoration(labelText: 'Wdh'),
                          keyboardType: TextInputType.number,
                        ),
                        TextField(
                          controller: rirCtr,
                          decoration: const InputDecoration(labelText: 'RIR'),
                          keyboardType: TextInputType.number,
                        ),
                        TextField(
                          controller: restCtr,
                          decoration: const InputDecoration(
                            labelText: 'Pause (s)',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        TextField(
                          controller: notesCtr,
                          decoration: const InputDecoration(labelText: 'Notiz'),
                        ),
                      ],
                    ),
                  ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Abbrechen'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (selectedDevice == null) return;
                  final entry = ExerciseEntry(
                    deviceId: selectedDevice!.id,
                    exerciseId: selectedExercise?.id ?? selectedDevice!.id,
                    setType: setTypeCtr.text,
                    totalSets: int.tryParse(setsCtr.text) ?? 0,
                    workSets: int.tryParse(workCtr.text) ?? 0,
                    reps: int.tryParse(repsCtr.text) ?? 0,
                    rir: int.tryParse(rirCtr.text) ?? 0,
                    restInSeconds: int.tryParse(restCtr.text) ?? 0,
                    notes: notesCtr.text.isEmpty ? null : notesCtr.text,
                  );
                  Navigator.pop(context, entry);
                },
                child: const Text('Speichern'),
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
          tabs: [for (var d in widget.week.days) Tab(text: d.day)],
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
                      key: ValueKey('${day.day}-$index'),
                      background: Container(color: Colors.red),
                      onDismissed:
                          (_) =>
                              prov.removeExercise(weekNumber, day.day, index),
                      child: ListTile(
                        title: Text('${ex.exerciseId} (${ex.setType})'),
                        subtitle: Text('${ex.reps}×${ex.workSets}'),
                        onTap: () async {
                          final updated = await _editEntry(context, entry: ex);
                          if (updated != null && mounted) {
                            prov.updateExercise(
                              weekNumber,
                              day.day,
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

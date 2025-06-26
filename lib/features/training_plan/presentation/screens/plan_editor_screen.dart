import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/device_provider.dart';
import '../../../../core/providers/training_plan_provider.dart';
import '../../../device/domain/models/device.dart';
import '../../../device/domain/models/exercise.dart';
import '../../domain/models/exercise_entry.dart';

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

  Future<ExerciseEntry?> _editEntry(BuildContext context) async {
    final gymId = context.read<AuthProvider>().gymId!;
    await context.read<DeviceProvider>().loadDevices(gymId);
    final devices = context.read<DeviceProvider>().devices;
    Device? selectedDevice;
    Exercise? selectedExercise;
    final setTypeCtr = TextEditingController();
    final setsCtr = TextEditingController();
    final workCtr = TextEditingController();
    final repsCtr = TextEditingController();
    final rirCtr = TextEditingController();
    final restCtr = TextEditingController();
    final notesCtr = TextEditingController();

    return showDialog<ExerciseEntry>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Übung hinzufügen'),
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
                                .read<DeviceProvider>()
                                .loadExercises(gymId, selectedDevice!.id),
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
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }
}

class _WeekView extends StatelessWidget {
  final WeekBlock week;
  const _WeekView({required this.week});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        for (var day in week.days)
          Card(
            margin: const EdgeInsets.all(12),
            child: ExpansionTile(
              title: Text(day.day),
              children: [
                for (var ex in day.exercises)
                  ListTile(
                    title: Text('${ex.exerciseId} (${ex.setType})'),
                    subtitle: Text('${ex.reps}×${ex.workSets}'),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

// lib/features/device/presentation/screens/device_screen.dart
// ignore_for_file: use_super_parameters

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:tapem/app_router.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/device_provider.dart';
import 'package:tapem/core/providers/training_plan_provider.dart';
import '../../../training_plan/domain/models/exercise_entry.dart';
import '../widgets/rest_timer_widget.dart';
import '../widgets/note_button_widget.dart';

class DeviceScreen extends StatefulWidget {
  final String gymId;
  final String deviceId;
  final String exerciseId;

  const DeviceScreen({
    Key? key,
    required this.gymId,
    required this.deviceId,
    required this.exerciseId,
  }) : super(key: key);

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _redirected = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      context.read<DeviceProvider>().loadDevice(
        gymId: widget.gymId,
        deviceId: widget.deviceId,
        exerciseId: widget.exerciseId,
        userId: auth.userId!,
      );
      final planProv = context.read<TrainingPlanProvider>();
      if (planProv.plans.isEmpty && !planProv.isLoading) {
        planProv.loadPlans(widget.gymId, auth.userId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<DeviceProvider>();
    final locale = Localizations.localeOf(context).toString();
    final planProv = context.watch<TrainingPlanProvider>();
    final plannedEntry = planProv.entryForDate(
      widget.deviceId,
      widget.exerciseId,
      DateTime.now(),
    );

    if (prov.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (prov.error != null || prov.device == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Gerät nicht gefunden')),
        body: Center(child: Text('Fehler: ${prov.error ?? "Unbekannt"}')),
      );
    }

    // **Nur** Multi + initialId==deviceId => ExerciseList
    if (!_redirected &&
        prov.device!.isMulti &&
        widget.exerciseId == widget.deviceId) {
      _redirected = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed(
          AppRouter.exerciseList,
          arguments: {'gymId': widget.gymId, 'deviceId': widget.deviceId},
        );
      });
      return const Scaffold();
    }

    // Single-Übung: hier bleiben
    return Scaffold(
      appBar: AppBar(
        title: Text(prov.device!.name),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Verlauf',
            onPressed: () {
              Navigator.of(
                context,
              ).pushNamed(AppRouter.history, arguments: widget.deviceId);
            },
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: NoteButtonWidget(deviceId: widget.deviceId),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (prov.device!.description.isNotEmpty) ...[
                      Text(
                        prov.device!.description,
                        style: const TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (prov.lastSessionSets.isNotEmpty) ...[
                      Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Letzte Session: ${DateFormat.yMd(locale).add_Hm().format(prov.lastSessionDate!)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              for (var set in prov.lastSessionSets)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 24,
                                      child: Text(set['number']!),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text('${set['weight']} kg'),
                                    ),
                                    const SizedBox(width: 16),
                                    Text('${set['reps']} x'),
                                    if (set['rir'] != null && set['rir']!.isNotEmpty) ...[
                                      const SizedBox(width: 16),
                                      Text('RIR ${set['rir']}'),
                                    ],
                                    if (set['note'] != null && set['note']!.isNotEmpty) ...[
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Text(set['note']!),
                                      ),
                                    ],
                                  ],
                                ),
                              if (prov.lastSessionNote.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text('Notiz: ${prov.lastSessionNote}'),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                    const Divider(),
                    if (plannedEntry != null)
                      _PlannedTable(entry: plannedEntry)
                    else ...[
                      const Text(
                        'Neue Session',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (var entry in prov.sets.asMap().entries)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              SizedBox(
                              width: 24,
                              child: Text(entry.value['number']!),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                initialValue: entry.value['weight'],
                                decoration: const InputDecoration(
                                  labelText: 'kg',
                                  isDense: true,
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (v) {
                                  prov.updateSet(
                                    entry.key,
                                    weight: v,
                                  );
                                },
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Gewicht?';
                                  }
                                  if (double.tryParse(v) == null) {
                                    return 'Zahl eingeben';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                initialValue: entry.value['reps'],
                                decoration: const InputDecoration(
                                  labelText: 'x',
                                  isDense: true,
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (v) {
                                  prov.updateSet(
                                    entry.key,
                                    reps: v,
                                  );
                                },
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Wdh.?';
                                  }
                                  if (int.tryParse(v) == null) {
                                    return 'Ganzzahl';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                initialValue: entry.value['rir'],
                                decoration: const InputDecoration(
                                  labelText: 'RIR',
                                  isDense: true,
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (v) {
                                  prov.updateSet(
                                    entry.key,
                                    rir: v,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                initialValue: entry.value['note'],
                                decoration: const InputDecoration(
                                  labelText: 'Notiz',
                                  isDense: true,
                                ),
                                onChanged: (v) {
                                  prov.updateSet(
                                    entry.key,
                                    note: v,
                                  );
                                },
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () {
                                prov.removeSet(entry.key);
                              },
                            ),
                          ],
                        ),
                      ),
                    TextButton.icon(
                      onPressed: () {
                        prov.addSet();
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Set hinzufügen'),
                    ),
                    const Divider(),
                    const RestTimerWidget(),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Abbrechen'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        try {
                          await prov.saveWorkoutSession(
                            gymId: widget.gymId,
                            userId: context.read<AuthProvider>().userId!,
                            showInLeaderboard:
                                context
                                    .read<AuthProvider>()
                                    .showInLeaderboard ??
                                true,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Session gespeichert'),
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Fehler: $e')));
                        }
                      }
                    },
                    child: const Text('Speichern'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlannedTable extends StatelessWidget {
  final ExerciseEntry entry;

  const _PlannedTable({required this.entry});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<DeviceProvider>();

    if (prov.sets.length < entry.totalSets) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        while (prov.sets.length < entry.totalSets) {
          prov.addSet();
        }
        for (var i = 0; i < prov.sets.length; i++) {
          final set = prov.sets[i];
          if ((set['reps'] ?? '').isEmpty) {
            prov.updateSet(i, reps: entry.reps?.toString() ?? '');
          }
          if ((set['rir'] ?? '').isEmpty) {
            prov.updateSet(i, rir: entry.rir.toString());
          }
        }
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Heute dran',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        for (final entrySet in prov.sets.asMap().entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  child: Text(entrySet.value['number']!),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: entrySet.value['weight'],
                    decoration: const InputDecoration(
                      labelText: 'kg',
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => prov.updateSet(
                      entrySet.key,
                      weight: v,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: entrySet.value['reps'],
                    decoration: const InputDecoration(
                      labelText: 'x',
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => prov.updateSet(
                      entrySet.key,
                      reps: v,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: entrySet.value['rir'],
                    decoration: const InputDecoration(
                      labelText: 'RIR',
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => prov.updateSet(
                      entrySet.key,
                      rir: v,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    initialValue: entrySet.value['note'],
                    decoration: const InputDecoration(
                      labelText: 'Notiz',
                      isDense: true,
                    ),
                    onChanged: (v) => prov.updateSet(
                      entrySet.key,
                      note: v,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => prov.removeSet(entrySet.key),
                ),
              ],
            ),
          ),
        TextButton.icon(
          onPressed: () => prov.addSet(),
          icon: const Icon(Icons.add),
          label: const Text('Set hinzufügen'),
        ),
        if (entry.notes != null && entry.notes!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('Notiz: ${entry.notes!}'),
        ],
        const Divider(),
        const RestTimerWidget(),
      ],
    );
  }
}

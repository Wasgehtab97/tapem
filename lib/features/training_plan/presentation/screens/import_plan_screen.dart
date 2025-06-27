import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/training_plan_provider.dart';
import '../../../../core/providers/device_provider.dart';
import '../../../../core/providers/exercise_provider.dart';
import '../../../device/domain/models/device.dart';
import '../../../device/domain/models/exercise.dart';
import '../../domain/models/exercise_entry.dart';

class ImportPlanScreen extends StatefulWidget {
  const ImportPlanScreen({super.key});

  @override
  State<ImportPlanScreen> createState() => _ImportPlanScreenState();
}

class _ImportPlanScreenState extends State<ImportPlanScreen> {
  final _csvCtr = TextEditingController();

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result != null) {
      final file = result.files.single;
      String content = '';
      if (file.bytes != null) {
        content = utf8.decode(file.bytes!);
      } else if (file.path != null) {
        content = await File(file.path!).readAsString();
      }
      setState(() => _csvCtr.text = content);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plan importieren')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _pickFile,
              child: const Text('CSV-Datei wählen'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _csvCtr,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'CSV-Daten einfügen',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final csv = const CsvToListConverter(
                  eol: '\n',
                ).convert(_csvCtr.text);
                _handleCsv(context, csv);
              },
              child: const Text('Importieren'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleCsv(BuildContext context, List<List<dynamic>> data) {
    if (data.isEmpty) return;

    String n(String h) => h.trim().toLowerCase();
    final headerMap = <String, int>{};
    for (var i = 0; i < data.first.length; i++) {
      headerMap[n(data.first[i].toString())] = i;
    }

    final requiredCols = [
      'woche',
      'tag',
      'übung',
      'art des satzes',
      'arbeitssätze',
      'reps',
      'rir',
      'pausenzeit',
    ];
    final missing =
        requiredCols.where((c) => !headerMap.containsKey(c)).toList();
    if (missing.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Spalten fehlen: ${missing.join(', ')}')),
      );
      return;
    }

    final weekIdx = headerMap['woche']!;
    final dayIdx = headerMap['tag']!;
    final repsIdx = headerMap['reps']!;
    final prov = context.read<TrainingPlanProvider>();
    final userId = context.read<AuthProvider>().userId!;
    prov.createNewPlan('Import', userId);
    for (var row in data.skip(1)) {
      final week = int.tryParse(row[weekIdx].toString()) ?? 1;
      final day = row[dayIdx].toString();
      final entry = ExerciseEntry(
        deviceId: '',
        exerciseId: row[headerMap['übung']!].toString(),
        setType: row[headerMap['art des satzes']!].toString(),
        totalSets:
            int.tryParse(row[headerMap['arbeitssätze']!].toString()) ?? 0,
        workSets: int.tryParse(row[headerMap['arbeitssätze']!].toString()) ?? 0,
        reps: int.tryParse(row[repsIdx].toString()) ?? 0,
        rir: int.tryParse(row[headerMap['rir']!].toString()) ?? 0,
        restInSeconds:
            int.tryParse(row[headerMap['pausenzeit']!].toString()) ?? 0,
        notes:
            headerMap.containsKey('notiz')
                ? row[headerMap['notiz']!].toString()
                : '',
      );
      prov.addExercise(week, day, entry);
    }
    _assignDevices(context).then((_) async {
      final gymId = context.read<AuthProvider>().gymCode!;
      await prov.saveCurrentPlan(gymId);
      if (context.mounted) Navigator.pop(context);
    });
  }

  Future<void> _assignDevices(BuildContext context) async {
    final prov = context.read<TrainingPlanProvider>();
    final plan = prov.currentPlan!;
    final gymId = context.read<AuthProvider>().gymCode!;
    final userId = context.read<AuthProvider>().userId!;

    final deviceProv = context.read<DeviceProvider>();
    await deviceProv.loadDevices(gymId);
    final devices = deviceProv.devices;
    final exProv = context.read<ExerciseProvider>();

    for (var week in plan.weeks) {
      for (var day in week.days) {
        for (var i = 0; i < day.exercises.length; i++) {
          final updated = await _selectDevice(
            context,
            day.exercises[i],
            devices,
            exProv,
            gymId,
            userId,
          );
          if (updated != null) {
            day.exercises[i] = updated;
          }
        }
      }
    }
    prov.notify();
  }

  Future<ExerciseEntry?> _selectDevice(
    BuildContext context,
    ExerciseEntry entry,
    List<Device> devices,
    ExerciseProvider exProv,
    String gymId,
    String userId,
  ) async {
    Device? selectedDevice;
    Exercise? selectedExercise;

    return showDialog<ExerciseEntry>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
            title: Text('Gerät für ${entry.exerciseId} wählen'),
            content: StatefulBuilder(
              builder:
                  (ctx, setState) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButton<Device>(
                        value: selectedDevice,
                        isExpanded: true,
                        hint: const Text('Gerät wählen'),
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
                          future: exProv
                              .loadExercises(gymId, selectedDevice!.id, userId)
                              .then((_) => exProv.exercises),
                          builder: (ctx, snapshot) {
                            final exList = snapshot.data ?? [];
                            return DropdownButton<Exercise>(
                              value: selectedExercise,
                              isExpanded: true,
                              hint: const Text('Übung wählen'),
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
                    ],
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
                  final newEntry = ExerciseEntry(
                    deviceId: selectedDevice!.id,
                    exerciseId:
                        selectedDevice!.isMulti
                            ? (selectedExercise?.id ?? '')
                            : selectedDevice!.id,
                    setType: entry.setType,
                    totalSets: entry.totalSets,
                    workSets: entry.workSets,
                    reps: entry.reps,
                    rir: entry.rir,
                    restInSeconds: entry.restInSeconds,
                    notes: entry.notes,
                  );
                  Navigator.pop(context, newEntry);
                },
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }
}

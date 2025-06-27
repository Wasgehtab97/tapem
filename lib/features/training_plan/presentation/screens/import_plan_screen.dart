import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/training_plan_provider.dart';
import '../../domain/models/exercise_entry.dart';

class ImportPlanScreen extends StatefulWidget {
  const ImportPlanScreen({super.key});

  @override
  State<ImportPlanScreen> createState() => _ImportPlanScreenState();
}

class _ImportPlanScreenState extends State<ImportPlanScreen> {
  final _csvCtr = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plan importieren')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
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
    final headers = data.first.map((e) => e.toString().toLowerCase()).toList();
    final weekIdx = headers.indexOf('woche');
    final dayIdx = headers.indexOf('tag');
    final repsIdx = headers.indexOf('reps');
    if (weekIdx == -1 || dayIdx == -1 || repsIdx == -1) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Benötigte Spalten fehlen')));
      return;
    }
    final prov = context.read<TrainingPlanProvider>();
    prov.createNewPlan('Import');
    for (var row in data.skip(1)) {
      final week = int.tryParse(row[weekIdx].toString()) ?? 1;
      final day = row[dayIdx].toString();
      final entry = ExerciseEntry(
        deviceId: '',
        exerciseId: row[headers.indexOf('übung')].toString(),
        setType: row[headers.indexOf('art des satzes')].toString(),
        totalSets:
            int.tryParse(row[headers.indexOf('arbeitssätze')].toString()) ?? 0,
        workSets:
            int.tryParse(row[headers.indexOf('arbeitssätze')].toString()) ?? 0,
        reps: int.tryParse(row[repsIdx].toString()) ?? 0,
        rir: int.tryParse(row[headers.indexOf('rir')].toString()) ?? 0,
        restInSeconds:
            int.tryParse(row[headers.indexOf('pausenzeit')].toString()) ?? 0,
        notes: '',
      );
      prov.addExercise(week, day, entry);
    }
    final gymId = context.read<AuthProvider>().gymCode!;
    prov.saveCurrentPlan(gymId);
    Navigator.pop(context);
  }
}

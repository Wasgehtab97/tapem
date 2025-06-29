import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/device_provider.dart';
import '../../../../core/providers/exercise_provider.dart';
import '../../../device/domain/models/device.dart';
import '../../../device/domain/models/exercise.dart';
import '../../domain/models/exercise_entry.dart';

Future<ExerciseEntry?> showDeviceSelectionDialog(
  BuildContext context,
  ExerciseEntry entry,
) async {
  final gymId = context.read<AuthProvider>().gymCode!;
  final userId = context.read<AuthProvider>().userId!;
  final deviceProv = context.read<DeviceProvider>();
  await deviceProv.loadDevices(gymId);
  final devices = deviceProv.devices;
  final exProv = context.read<ExerciseProvider>();

  Device? selectedDevice;
  Exercise? selectedExercise;
  Future<List<Exercise>>? exerciseFuture;

  // Vorbelegung basierend auf vorhandenem Eintrag
  try {
    selectedDevice = devices.firstWhere((d) => d.id == entry.deviceId);
  } catch (_) {
    if (devices.isNotEmpty) selectedDevice = devices.first;
  }

  if (selectedDevice?.isMulti == true) {
    exerciseFuture = exProv
        .loadExercises(gymId, selectedDevice!.id, userId)
        .then((_) => exProv.exercises);
    final exList = await exerciseFuture;
    try {
      selectedExercise = exList.firstWhere((e) => e.id == entry.exerciseId);
    } catch (_) {
      if (exList.isNotEmpty) selectedExercise = exList.first;
    }
  }

  return showDialog<ExerciseEntry>(
    context: context,
    barrierDismissible: false,
    builder:
        (_) => AlertDialog(
          title: const Text('Gerät wählen'),
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
                      onChanged: (d) {
                        setState(() {
                          selectedDevice = d;
                          selectedExercise = null;
                          if (selectedDevice?.isMulti == true) {
                            exerciseFuture = exProv
                                .loadExercises(
                                  gymId,
                                  selectedDevice!.id,
                                  userId,
                                )
                                .then((_) => exProv.exercises);
                          } else {
                            exerciseFuture = null;
                          }
                        });
                      },
                    ),
                    if (selectedDevice?.isMulti == true)
                      FutureBuilder<List<Exercise>>(
                        future: exerciseFuture,
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
                final result = ExerciseEntry(
                  deviceId: selectedDevice!.id,
                  exerciseId:
                      selectedDevice!.isMulti
                          ? (selectedExercise?.id ?? '')
                          : selectedDevice!.id,
                  exerciseName:
                      selectedDevice!.isMulti
                          ? (selectedExercise?.name ?? selectedDevice!.name)
                          : selectedDevice!.name,
                  setType: entry.setType,
                  totalSets: entry.totalSets,
                  workSets: entry.workSets,
                  reps: entry.reps,
                  rir: entry.rir,
                  restInSeconds: entry.restInSeconds,
                  notes: entry.notes,
                  sets: entry.sets,
                );
                Navigator.pop(context, result);
              },
              child: const Text('OK'),
            ),
          ],
        ),
  );
}

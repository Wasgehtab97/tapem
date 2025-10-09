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
  await deviceProv.loadDevices(gymId, userId);
  final devices = List<Device>.from(deviceProv.devices)
    ..sort((a, b) => a.name.compareTo(b.name));
  final exProv = context.read<ExerciseProvider>();

  Device? selectedDevice;
  if (entry.deviceId.isNotEmpty) {
    try {
      selectedDevice = devices.firstWhere((d) => d.uid == entry.deviceId);
    } catch (_) {
      selectedDevice = null;
    }
  }
  Future<List<Exercise>>? exerciseFuture;

  if (selectedDevice?.isMulti == true) {
    exerciseFuture = exProv
        .loadExercises(gymId, selectedDevice!.uid, userId)
        .then((_) => List<Exercise>.from(exProv.exercises));
  }

  final searchController = TextEditingController();
  String searchTerm = '';
  String? selectedMuscleGroup;

  final allGroups = <String>{
    for (final device in devices) ...device.muscleGroups,
  }..removeWhere((element) => element.trim().isEmpty);
  final sortedGroups = allGroups.toList()..sort();

  ExerciseEntry buildResult({required Device device, Exercise? exercise}) {
    return ExerciseEntry(
      deviceId: device.uid,
      exerciseId: device.isMulti ? (exercise?.id ?? '') : device.uid,
      exerciseName:
          device.isMulti ? (exercise?.name ?? device.name) : device.name,
      setType: entry.setType,
      totalSets: entry.totalSets,
      workSets: entry.workSets,
      reps: entry.reps,
      restInSeconds: entry.restInSeconds,
      notes: entry.notes,
      sets: entry.sets,
    );
  }

  return showDialog<ExerciseEntry>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          final lowerSearch = searchTerm.toLowerCase();
          final filteredDevices = devices.where((device) {
            final matchesSearch = lowerSearch.isEmpty ||
                device.name.toLowerCase().contains(lowerSearch) ||
                device.muscleGroups.any(
                  (g) => g.toLowerCase().contains(lowerSearch),
                );
            final matchesGroup = selectedMuscleGroup == null ||
                device.muscleGroups.contains(selectedMuscleGroup);
            return matchesSearch && matchesGroup;
          }).toList();

          return AlertDialog(
            title: Text(
              selectedDevice?.isMulti == true ? 'Übung wählen' : 'Gerät wählen',
            ),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      labelText: 'Suche',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchTerm = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    value: selectedMuscleGroup,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Muskelgruppe',
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Alle'),
                      ),
                      for (final group in sortedGroups)
                        DropdownMenuItem<String?>(
                          value: group,
                          child: Text(group),
                        ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedMuscleGroup = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  if (selectedDevice?.isMulti == true)
                    Expanded(
                      child: FutureBuilder<List<Exercise>>(
                        future: exerciseFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          final exercises = snapshot.data ?? [];
                          final filteredExercises = exercises.where((ex) {
                            final matchesSearch = lowerSearch.isEmpty ||
                                ex.name.toLowerCase().contains(lowerSearch);
                            final matchesGroup = selectedMuscleGroup == null ||
                                ex.muscleGroupIds
                                    .contains(selectedMuscleGroup);
                            return matchesSearch && matchesGroup;
                          }).toList()
                            ..sort((a, b) => a.name.compareTo(b.name));

                          if (filteredExercises.isEmpty) {
                            return const Center(
                              child: Text('Keine Übungen gefunden'),
                            );
                          }

                          return ListView.builder(
                            itemCount: filteredExercises.length,
                            itemBuilder: (context, index) {
                              final exercise = filteredExercises[index];
                              return ListTile(
                                title: Text(exercise.name),
                                subtitle: exercise.muscleGroupIds.isEmpty
                                    ? null
                                    : Text(exercise.muscleGroupIds.join(', ')),
                                onTap: () => Navigator.pop(
                                  dialogContext,
                                  buildResult(
                                    device: selectedDevice!,
                                    exercise: exercise,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    )
                  else
                    Expanded(
                      child: filteredDevices.isEmpty
                          ? const Center(
                              child: Text('Keine Geräte gefunden'),
                            )
                          : ListView.builder(
                              itemCount: filteredDevices.length,
                              itemBuilder: (context, index) {
                                final device = filteredDevices[index];
                                return ListTile(
                                  title: Text(device.name),
                                  subtitle: device.muscleGroups.isEmpty
                                      ? null
                                      : Text(device.muscleGroups.join(', ')),
                                  trailing: device.isMulti
                                      ? const Icon(Icons.chevron_right)
                                      : null,
                                  onTap: () {
                                    if (device.isMulti) {
                                      setState(() {
                                        selectedDevice = device;
                                        exerciseFuture = exProv
                                            .loadExercises(
                                              gymId,
                                              device.uid,
                                              userId,
                                            )
                                            .then(
                                              (_) =>
                                                  List<Exercise>.from(exProv.exercises),
                                            );
                                      });
                                    } else {
                                      Navigator.pop(
                                        dialogContext,
                                        buildResult(device: device),
                                      );
                                    }
                                  },
                                );
                              },
                            ),
                    ),
                ],
              ),
            ),
            actions: [
              if (selectedDevice?.isMulti == true)
                TextButton(
                  onPressed: () {
                    setState(() {
                      selectedDevice = null;
                      exerciseFuture = null;
                    });
                  },
                  child: const Text('Zurück'),
                ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Abbrechen'),
              ),
            ],
          );
        },
      );
    },
  );
}

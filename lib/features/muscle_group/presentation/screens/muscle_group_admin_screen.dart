import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/providers/gym_provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/muscle_group_provider.dart';
import '../../../../core/providers/all_exercises_provider.dart';
import '../../domain/models/muscle_group.dart';


class MuscleGroupAdminScreen extends StatefulWidget {
  const MuscleGroupAdminScreen({Key? key}) : super(key: key);

  @override
  State<MuscleGroupAdminScreen> createState() => _MuscleGroupAdminScreenState();
}

class _MuscleGroupAdminScreenState extends State<MuscleGroupAdminScreen> {
  final Uuid _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MuscleGroupProvider>().loadGroups(context);
      final auth = context.read<AuthProvider>();
      final gym = context.read<GymProvider>();
      final allEx = context.read<AllExercisesProvider>();
      final gymId = auth.gymCode;
      final userId = auth.userId;
      if (gymId != null && userId != null && gym.devices.isNotEmpty) {
        allEx.loadAll(
          gymId,
          gym.devices.map((d) => d.uid).toList(),
          userId,
        );
      }
    });
  }

  Future<void> _showEditDialog({MuscleGroup? group}) async {
    final devices =
        context.read<GymProvider>().devices.where((d) => !d.isMulti).toList();
    final Set<String> selectedDevices = <String>{};
    if (group != null) {
      selectedDevices
        ..addAll(group.primaryDeviceIds)
        ..addAll(group.secondaryDeviceIds);
    }
    final selectedRegions = group == null
        ? <MuscleRegion>[]
        : <MuscleRegion>[group.region];

    // no exercises needed

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setSt) => AlertDialog(
          title: Text(group == null
              ? 'Muskelgruppe hinzufügen'
              : 'Muskelgruppe bearbeiten'),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  spacing: 4,
                  children: [
                    for (final r in MuscleRegion.values)
                      FilterChip(
                        label: Text(r.name),
                        selected: selectedRegions.contains(r),
                        selectedColor: selectedRegions.contains(r)
                            ? (selectedRegions.indexOf(r) == 0
                                ? Colors.blue
                                : Colors.yellow)
                            : null,
                        checkmarkColor: Colors.white,
                        onSelected: (v) => setSt(() {
                          if (v) {
                            if (!selectedRegions.contains(r)) {
                              selectedRegions.add(r);
                            }
                          } else {
                            selectedRegions.remove(r);
                          }
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Geräte', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(
                  height: 150,
                  child: ListView(
                    children: [
                      for (final d in devices)
                        CheckboxListTile(
                          value: selectedDevices.contains(d.uid),
                          title: Text(d.name),
                          onChanged: (v) => setSt(() {
                            if (v == true) {
                              selectedDevices.add(d.uid);
                            } else {
                              selectedDevices.remove(d.uid);
                            }
                          }),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx2).pop(),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () async {
                final prov = context.read<MuscleGroupProvider>();
                final deviceIds = selectedDevices.toList();
                if (selectedRegions.isEmpty || deviceIds.isEmpty) return;
                for (var i = 0; i < selectedRegions.length; i++) {
                  final r = selectedRegions[i];
                  final id = group?.id ?? _uuid.v4();
                  final newGroup = MuscleGroup(
                    id: id,
                    name: '',
                    region: r,
                    primaryDeviceIds: i == 0 ? deviceIds : const [],
                    secondaryDeviceIds: i == 0 ? const [] : deviceIds,
                    exerciseIds: const [],
                  );
                  await prov.saveGroup(context, newGroup);
                }
                if (!mounted) return;
                Navigator.of(ctx2).pop();
              },
              child: const Text('Speichern'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupProv = context.watch<MuscleGroupProvider>();
    final allExProv = context.watch<AllExercisesProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Muskelgruppen verwalten')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditDialog(),
        child: const Icon(Icons.add),
      ),
      body: groupProv.isLoading || allExProv.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: allExProv.allExercises.length,
              itemBuilder: (_, i) {
                final entry = allExProv.allExercises[i];
                final ex = entry.value;
                final deviceId = entry.key;
                final primary = <MuscleGroup>[];
                final secondary = <MuscleGroup>[];
                for (final g in groupProv.groups) {
                  if (!ex.muscleGroupIds.contains(g.id)) continue;
                  if (g.primaryDeviceIds.contains(deviceId)) {
                    primary.add(g);
                  } else if (g.secondaryDeviceIds.contains(deviceId)) {
                    secondary.add(g);
                  }
                }
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    title: Text(ex.name),
                    subtitle: Wrap(
                      spacing: 4,
                      children: [
                        for (final g in primary)
                          Chip(
                            label: Text(g.region.name),
                            backgroundColor: Colors.blue,
                            labelStyle: const TextStyle(color: Colors.white),
                          ),
                        for (final g in secondary)
                          Chip(
                            label: Text(g.region.name),
                            backgroundColor: Colors.yellow,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

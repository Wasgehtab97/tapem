import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/providers/gym_provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/muscle_group_provider.dart';
import '../../domain/models/muscle_group.dart';

enum MuscleRole { none, primary, secondary }

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
    });
  }

  Future<void> _showEditDialog({MuscleGroup? group}) async {
    final devices =
        context.read<GymProvider>().devices.where((d) => !d.isMulti).toList();
    final Map<String, MuscleRole> selectedDevices = {};
    if (group != null) {
      for (final id in group.primaryDeviceIds) {
        selectedDevices[id] = MuscleRole.primary;
      }
      for (final id in group.secondaryDeviceIds) {
        selectedDevices[id] = MuscleRole.secondary;
      }
    }
    final selectedRegions = group == null
        ? <MuscleRegion>{}
        : {group.region};

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
                        onSelected: (v) => setSt(() {
                          if (v) {
                            selectedRegions.add(r);
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
                        ListTile(
                          title: Text(d.name),
                          trailing: DropdownButton<MuscleRole>(
                            value: selectedDevices[d.uid] ?? MuscleRole.none,
                            onChanged: (v) => setSt(() {
                              if (v == null || v == MuscleRole.none) {
                                selectedDevices.remove(d.uid);
                              } else {
                                selectedDevices[d.uid] = v;
                              }
                            }),
                            items: const [
                              DropdownMenuItem(
                                value: MuscleRole.none,
                                child: Text('-'),
                              ),
                              DropdownMenuItem(
                                value: MuscleRole.primary,
                                child: Text('Primär'),
                              ),
                              DropdownMenuItem(
                                value: MuscleRole.secondary,
                                child: Text('Sekundär'),
                              ),
                            ],
                          ),
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
                final primary = <String>[];
                final secondary = <String>[];
                selectedDevices.forEach((key, value) {
                  if (value == MuscleRole.primary) primary.add(key);
                  if (value == MuscleRole.secondary) secondary.add(key);
                });
                if (selectedRegions.isEmpty || primary.isEmpty && secondary.isEmpty) return;
                for (final r in selectedRegions) {
                  final id = group?.id ?? _uuid.v4();
                  final newGroup = MuscleGroup(
                    id: id,
                    name: '',
                    region: r,
                    primaryDeviceIds: primary,
                    secondaryDeviceIds: secondary,
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
    final prov = context.watch<MuscleGroupProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Muskelgruppen verwalten')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditDialog(),
        child: const Icon(Icons.add),
      ),
      body: prov.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: prov.groups.length,
              itemBuilder: (_, i) {
                final g = prov.groups[i];
                return ListTile(
                  title: Text(g.region.name),
                  subtitle:
                      Text('${g.deviceIds.length} Geräte'),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showEditDialog(group: g),
                  ),
                );
              },
            ),
    );
  }
}

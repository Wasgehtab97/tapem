import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/providers/gym_provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../features/device/domain/usecases/get_exercises_for_device.dart';
import '../../../../core/providers/muscle_group_provider.dart';
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
    });
  }

  Future<void> _showEditDialog({MuscleGroup? group}) async {
    final devices =
        context.read<GymProvider>().devices.where((d) => !d.isMulti).toList();
    final selectedDevices = group == null
        ? <String>{}
        : group.deviceIds.toSet();
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
                if (selectedRegions.isEmpty || selectedDevices.isEmpty) return;
                for (final r in selectedRegions) {
                  final id = group?.id ?? _uuid.v4();
                  final newGroup = MuscleGroup(
                    id: id,
                    name: '',
                    region: r,
                    deviceIds: selectedDevices.toList(),
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
                  subtitle: Text('${g.deviceIds.length} Geräte'),
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

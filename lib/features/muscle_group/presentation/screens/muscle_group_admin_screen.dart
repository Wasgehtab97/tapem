import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/providers/gym_provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/muscle_group_provider.dart';
import '../../domain/models/muscle_group.dart';


class MuscleGroupAdminScreen extends StatefulWidget {
  const MuscleGroupAdminScreen({Key? key}) : super(key: key);

  @override
  State<MuscleGroupAdminScreen> createState() => _MuscleGroupAdminScreenState();
}

class _MuscleGroupAdminScreenState extends State<MuscleGroupAdminScreen> {
  final Uuid _uuid = const Uuid();
  final TextEditingController _filterCtr = TextEditingController();
  String _filter = '';

  @override
  void dispose() {
    _filterCtr.dispose();
    super.dispose();
  }

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

  Future<void> _showDeviceDialog(String deviceId, String deviceName) async {
    final prov = context.read<MuscleGroupProvider>();
    final selected = <String>[];
    for (final g in prov.groups) {
      if (g.primaryDeviceIds.contains(deviceId)) {
        selected.insert(0, g.id);
      } else if (g.secondaryDeviceIds.contains(deviceId)) {
        selected.add(g.id);
      }
    }

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setSt) => AlertDialog(
          title: Text('Gerät: $deviceName'),
          content: SizedBox(
            width: 300,
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final g in prov.groups)
                  CheckboxListTile(
                    value: selected.contains(g.id),
                    title: Text(
                      selected.isNotEmpty && selected.first == g.id
                          ? '${g.region.name} (Primär)'
                          : g.region.name,
                    ),
                    onChanged: (v) => setSt(() {
                      if (v == true) {
                        selected.add(g.id);
                      } else {
                        selected.remove(g.id);
                      }
                    }),
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
                final List<String> primary =
                    selected.isNotEmpty ? [selected.first] : <String>[];
                final List<String> secondary =
                    selected.length > 1 ? selected.sublist(1) : <String>[];
                await prov.updateDeviceAssignments(
                  context,
                  deviceId,
                  primary,
                  secondary,
                );
                if (mounted) Navigator.of(ctx2).pop();
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
    final gymProv = context.watch<GymProvider>();

    final devices = gymProv.devices.where(
      (d) => groupProv.groups.any(
        (g) => g.primaryDeviceIds.contains(d.uid) ||
            g.secondaryDeviceIds.contains(d.uid),
      ),
    ).toList();

    final filteredDevices = devices.where((d) {
      if (_filter.isEmpty) return true;
      final f = _filter.toLowerCase();
      return groupProv.groups.any(
        (g) => g.primaryDeviceIds.contains(d.uid) &&
            g.region.name.toLowerCase().contains(f),
      );
    }).toList();

return Scaffold(
  appBar: AppBar(title: const Text('Muskelgruppen verwalten')),
  floatingActionButton: FloatingActionButton(
    onPressed: () => _showEditDialog(),
    child: const Icon(Icons.add),
  ),
  body: groupProv.isLoading || gymProv.isLoading
      ? const Center(child: CircularProgressIndicator())
      : Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _filterCtr,
                decoration: const InputDecoration(
                  labelText: 'Filter Primärgruppe',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (v) => setState(() => _filter = v),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: filteredDevices.length,
                itemBuilder: (_, i) {
                  final device = filteredDevices[i];
                  final primary = <MuscleGroup>[];
                  final secondary = <MuscleGroup>[];
                  for (final g in groupProv.groups) {
                    if (g.primaryDeviceIds.contains(device.uid)) {
                      primary.add(g);
                    } else if (g.secondaryDeviceIds.contains(device.uid)) {
                      secondary.add(g);
                    }
                  }
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: ListTile(
                      leading: Text('${device.id}'),
                      title: Text(device.name),
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
                      onTap: () => _showDeviceDialog(device.uid, device.name),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
    );
  }
}

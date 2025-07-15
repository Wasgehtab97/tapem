import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/providers/gym_provider.dart';
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

  void _showEditDialog({MuscleGroup? group}) {
    final nameCtrl = TextEditingController(text: group?.name ?? '');
    final devices = context.read<GymProvider>().devices;
    final selected = group == null
        ? <String>{}
        : group.deviceIds.toSet();

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setSt) => AlertDialog(
          title: Text(group == null
              ? 'Gruppe erstellen'
              : 'Gruppe bearbeiten'),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 200,
                  child: ListView(
                    children: [
                      for (final d in devices)
                        CheckboxListTile(
                          value: selected.contains(d.uid),
                          title: Text(d.name),
                          onChanged: (v) => setSt(() {
                            if (v == true) {
                              selected.add(d.uid);
                            } else {
                              selected.remove(d.uid);
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
                final id = group?.id ?? _uuid.v4();
                final newGroup = MuscleGroup(
                  id: id,
                  name: nameCtrl.text.trim(),
                  deviceIds: selected.toList(),
                );
                await context
                    .read<MuscleGroupProvider>()
                    .saveGroup(context, newGroup);
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
                  title: Text(g.name),
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

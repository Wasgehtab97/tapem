// lib/features/admin/presentation/screens/admin_dashboard_screen.dart

import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'package:uuid/uuid.dart';

import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/features/admin/presentation/widgets/device_list_item.dart';
import 'package:tapem/features/device/domain/models/device.dart';
import 'package:tapem/features/device/domain/usecases/create_device_usecase.dart';
import 'package:tapem/features/device/domain/usecases/get_devices_for_gym.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/providers/muscle_group_provider.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  // UseCases werden nur einmal initialisiert
  late final CreateDeviceUseCase _createUC;
  late final GetDevicesForGym _getUC;
  bool _dependenciesLoaded = false;

  final _uuid = const Uuid();
  List<Device> _devices = [];
  bool _loading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_dependenciesLoaded) {
      // Why? didChangeDependencies kann mehrfach aufgerufen werden
      _createUC = context.read<CreateDeviceUseCase>();
      _getUC = context.read<GetDevicesForGym>();
      _loadDevices();
      _dependenciesLoaded = true;
    }
  }

  Future<void> _loadDevices() async {
    setState(() => _loading = true);
    final gymId = context.read<AuthProvider>().gymCode!;
    _devices = await _getUC.execute(gymId);
    setState(() => _loading = false);
  }

  void _showCreateDialog() {
    final gymId = context.read<AuthProvider>().gymCode!;
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final newUid = _uuid.v4();
    final newId =
        _devices.isEmpty ? 1 : _devices.map((d) => d.id).reduce(max) + 1;
    bool isMulti = false;
    final muscleProv = context.read<MuscleGroupProvider>();
    muscleProv.loadGroups(context);
    final selectedGroups = <String>{};

    showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setSt) => AlertDialog(
          title: const Text('Neues Gerät anlegen'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Beschreibung'),
              ),
              const SizedBox(height: 8),
              const Text('Muskelgruppen',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(
                height: 150,
                child: ListView(
                  children: [
                    for (final g in muscleProv.groups)
                      CheckboxListTile(
                        value: selectedGroups.contains(g.id),
                        title: Text(g.name),
                        onChanged: (v) => setSt(() {
                          if (v == true) {
                            selectedGroups.add(g.id);
                          } else {
                            selectedGroups.remove(g.id);
                          }
                        }),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Mehrere Übungen?'),
                  Switch(
                    value: isMulti,
                    onChanged: (v) => setSt(() => isMulti = v),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Device ID: $newId',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx2).pop(false),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Token neu laden, damit Custom-Claims aktuell sind
                final fbUser = fb_auth.FirebaseAuth.instance.currentUser;
                if (fbUser != null) {
                  await fbUser.getIdToken(true);
                }

                final device = Device(
                  uid: newUid,
                  id: newId,
                  name: nameCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  isMulti: isMulti,
                );
                await _createUC.execute(
                  gymId: gymId,
                  device: device,
                  isMulti: isMulti,
                  muscleGroupIds: selectedGroups.toList(),
                );
                await muscleProv.assignDevice(
                  context,
                  newUid,
                  selectedGroups.toList(),
                );
                Navigator.of(ctx2).pop(true);
                await _loadDevices();
              },
              child: const Text('Erstellen'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Adminbereich')),
        body: const Center(child: Text('Keine Admin-Rechte')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Admin-Dashboard')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Gerät anlegen'),
                    onPressed: _showCreateDialog,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.fitness_center),
                    label: const Text('Muskelgruppen'),
                    onPressed: () {
                      Navigator.of(context).pushNamed(AppRouter.manageMuscleGroups);
                    },
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.brush),
                    label: const Text('Branding'),
                    onPressed: () {
                      Navigator.of(context).pushNamed(AppRouter.branding);
                    },
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.flag),
                    label: const Text('Challenges verwalten'),
                    onPressed: () {
                      Navigator.of(context).pushNamed(AppRouter.manageChallenges);
                    },
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: ListView.separated(
                      itemCount: _devices.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (_, i) {
                        final device = _devices[i];
                        return DeviceListItem(
                          device: device,
                          onDeleted: _loadDevices,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

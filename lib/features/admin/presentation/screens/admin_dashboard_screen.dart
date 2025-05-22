import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/features/device/domain/models/device.dart';
import 'package:tapem/features/device/domain/repositories/device_repository.dart';
import 'package:tapem/features/device/domain/usecases/get_devices_for_gym.dart';
import 'package:tapem/features/device/domain/usecases/create_device.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late final CreateDeviceUseCase _createUC;
  late final GetDevicesForGym _getUC;
  List<Device> _devices = [];

  @override
  void initState() {
    super.initState();
    final repo = context.read<DeviceRepository>();
    _createUC = CreateDeviceUseCase(repo);
    _getUC = GetDevicesForGym(repo);
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    final gymId = context.read<AuthProvider>().gymCode!;
    _devices = await _getUC.execute(gymId);
    setState(() {});
  }

  void _showCreateDialog() {
    final gymId = context.read<AuthProvider>().gymCode!;
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final uuid = const Uuid().v4();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Neues Gerät anlegen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Beschreibung')),
            const SizedBox(height: 8),
            Text('Device ID: $uuid', style: const TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
          ElevatedButton(
            onPressed: () async {
              final d = Device(id: uuid, name: nameCtrl.text, description: descCtrl.text);
              await _createUC.execute(gymId, d);
              Navigator.pop(context);
              await _loadDevices();
            },
            child: const Text('Erstellen'),
          ),
        ],
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Gerät anlegen'),
              onPressed: _showCreateDialog,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: _devices.length,
                itemBuilder: (_, i) {
                  final d = _devices[i];
                  return ListTile(
                    title: Text(d.name),
                    subtitle: Text(d.description),
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/features/device/domain/models/device.dart';
import 'package:tapem/features/device/domain/repositories/device_repository.dart';
import 'package:tapem/features/device/domain/usecases/create_device_usecase.dart';
import 'package:tapem/features/device/domain/usecases/get_devices_for_gym.dart';
import 'package:tapem/features/nfc/domain/usecases/write_nfc_tag.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late final CreateDeviceUseCase _createUC;
  late final GetDevicesForGym    _getUC;
  late final WriteNfcTagUseCase  _writeNfcUC;

  List<Device> _devices = [];
  bool         _loading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repo     = context.read<DeviceRepository>();
    _createUC      = CreateDeviceUseCase(repo);
    _getUC         = GetDevicesForGym(repo);
    _writeNfcUC    = context.read<WriteNfcTagUseCase>();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() => _loading = true);
    final gymId = context.read<AuthProvider>().gymCode!;
    _devices = await _getUC.execute(gymId);
    setState(() => _loading = false);
  }

  void _showCreateDialog() {
    final gymId   = context.read<AuthProvider>().gymCode!;
    final nameCtr = TextEditingController();
    final descCtr = TextEditingController();
    final id      = const Uuid().v4();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Neues Gerät anlegen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtr,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: descCtr,
              decoration: const InputDecoration(labelText: 'Beschreibung'),
            ),
            const SizedBox(height: 8),
            Text('Device ID: $id',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () async {
              final device = Device(
                id: id,
                name: nameCtr.text.trim(),
                description: descCtr.text.trim(),
              );
              await _createUC.execute(gymId, device);
              Navigator.pop(context);
              await _loadDevices();
            },
            child: const Text('Erstellen'),
          ),
        ],
      ),
    );
  }

  Future<void> _writeTag(String nfcCode) async {
    try {
      await _writeNfcUC.execute(nfcCode);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('NFC-Tag erfolgreich beschrieben')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Schreiben: $e')),
      );
    }
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
                  const SizedBox(height: 24),
                  Expanded(
                    child: ListView.separated(
                      itemCount: _devices.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (_, i) {
                        final d = _devices[i];
                        return ListTile(
                          title: Text(d.name),
                          subtitle: Text(d.description),
                          trailing: IconButton(
                            icon: const Icon(Icons.nfc),
                            tooltip: 'NFC-Tag beschreiben',
                            onPressed: d.nfcCode != null
                                ? () => _writeTag(d.nfcCode!)
                                : null,
                          ),
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

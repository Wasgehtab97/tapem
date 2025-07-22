import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/gym_provider.dart';
import '../../../../core/providers/xp_provider.dart';

class DeviceXpScreen extends StatefulWidget {
  const DeviceXpScreen({Key? key}) : super(key: key);

  @override
  State<DeviceXpScreen> createState() => _DeviceXpScreenState();
}

class _DeviceXpScreenState extends State<DeviceXpScreen> {
  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    final gymProv = context.read<GymProvider>();
    final xpProv = context.read<XpProvider>();
    final uid = auth.userId;
    final gymId = gymProv.currentGymId;
    if (uid != null && gymId.isNotEmpty) {
      final deviceIds = gymProv.devices
          .where((d) => !d.isMulti)
          .map((d) => d.uid)
          .toList();
      xpProv.watchDeviceXp(gymId, uid, deviceIds);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gymProv = context.watch<GymProvider>();
    final xpProv = context.watch<XpProvider>();
    final devices = gymProv.devices.where((d) => !d.isMulti).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Geräte XP')),
      body: ListView.builder(
        itemCount: devices.length,
        itemBuilder: (_, i) {
          final d = devices[i];
          final xp = xpProv.deviceXp[d.uid] ?? 0;
          return ListTile(
            title: Text(d.name),
            trailing: Text('$xp XP'),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/gym_provider.dart';
import '../../../../core/providers/xp_provider.dart';
import '../../../../core/logging/elog.dart';

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
        final deviceIds = gymProv.devices.map((d) => d.uid).toList();
        xpProv.watchDeviceXp(gymId, uid, deviceIds);
      }
  }

  @override
  Widget build(BuildContext context) {
      final gymProv = context.watch<GymProvider>();
      final xpProv = context.watch<XpProvider>();
      final devices = gymProv.devices.toList();
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
              onTap: () async {
                elogDeviceXp('OPEN_LEADERBOARD', {'deviceId': d.uid});
                final fs = FirebaseFirestore.instance;
                final gymId = gymProv.currentGymId;
                final snap = await fs
                    .collection('gyms')
                    .doc(gymId)
                    .collection('devices')
                    .doc(d.uid)
                    .collection('leaderboard')
                    .where('showInLeaderboard', isEqualTo: true)
                    .orderBy('xp', descending: true)
                    .limit(5)
                    .get();
                final entries = await Future.wait(
                  snap.docs.map((doc) async {
                    final user = await fs.collection('users').doc(doc.id).get();
                    final name = user.data()?['username'] as String? ?? doc.id;
                    final xp = doc.data()['xp'] as int? ?? 0;
                    return {'username': name, 'xp': xp};
                  }),
                );
              showDialog(
                context: context,
                builder:
                    (_) => AlertDialog(
                      title: Text(d.name),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final e in entries)
                            ListTile(
                              title: Text(e['username'] as String),
                              trailing: Text('${e['xp']} XP'),
                            ),
                        ],
                      ),
                    ),
              );
            },
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/gym_provider.dart';
import '../../../../core/providers/xp_provider.dart';
import '../../../../core/logging/elog.dart';
import 'package:tapem/features/friends/domain/models/public_profile.dart';
import 'package:tapem/features/friends/presentation/widgets/friend_list_tile.dart';
import 'leaderboard_screen.dart';

class DeviceXpScreen extends StatefulWidget {
  const DeviceXpScreen({Key? key}) : super(key: key);

  @override
  State<DeviceXpScreen> createState() => _DeviceXpScreenState();
}

class _DeviceXpScreenState extends State<DeviceXpScreen> {
  late final GymProvider _gymProv;
  late final XpProvider _xpProv;
  late final AuthProvider _auth;

  @override
  void initState() {
    super.initState();
    _gymProv = context.read<GymProvider>();
    _xpProv = context.read<XpProvider>();
    _auth = context.read<AuthProvider>();
    _gymProv.addListener(_syncWatchers);
    _syncWatchers();
  }

  void _syncWatchers() {
    final uid = _auth.userId;
    final gymId = _gymProv.currentGymId;
    if (uid != null && gymId.isNotEmpty) {
      final deviceIds = _gymProv.devices.map((d) => d.uid).toList();
      _xpProv.watchDeviceXp(gymId, uid, deviceIds);
    }
  }

  @override
  void dispose() {
    _gymProv.removeListener(_syncWatchers);
    final uid = _auth.userId;
    final gymId = _gymProv.currentGymId;
    if (uid != null && gymId.isNotEmpty) {
      _xpProv.watchDeviceXp(gymId, uid, []);
    }
    super.dispose();
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
                    final profile = PublicProfile.fromMap(
                        doc.id, user.data() ?? <String, dynamic>{});
                    final xp = doc.data()['xp'] as int? ?? 0;
                    return LeaderboardEntry(profile: profile, xp: xp);
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
                          for (final e in entries.asMap().entries)
                            FriendListTile(
                              profile: e.value.profile,
                              subtitle: '#${e.key + 1}',
                              trailing: Text('${e.value.xp} XP'),
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

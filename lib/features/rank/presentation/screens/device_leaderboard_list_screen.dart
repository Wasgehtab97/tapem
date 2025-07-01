// lib/features/rank/presentation/screens/device_leaderboard_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/gym_provider.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/features/rank/presentation/screens/rank_screen.dart';

class DeviceLeaderboardListScreen extends StatelessWidget {
  final String gymId;
  const DeviceLeaderboardListScreen({Key? key, required this.gymId})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final gymProv = context.watch<GymProvider>();
    final devices = gymProv.devices.where((d) => d.isMulti == false).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Geräte-Auswahl')),
      body: ListView.builder(
        itemCount: devices.length,
        itemBuilder: (_, i) {
          final d = devices[i];
          return ListTile(
            title: Text(d.name),
            subtitle: Text('Code: ${d.id}'),
            onTap: () {
              Navigator.of(context).pushNamed(
                AppRouter.rank, // <-- hier angepasst
                arguments: gymId,
              );
            },
          );
        },
      ),
    );
  }
}

// lib/features/rank/presentation/screens/rank_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/rank_provider.dart';

class RankScreen extends StatefulWidget {
  final String gymId;
  final String deviceId;
  const RankScreen({Key? key, required this.gymId, required this.deviceId}) : super(key: key);

  @override
  State<RankScreen> createState() => _RankScreenState();
}

class _RankScreenState extends State<RankScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RankProvider>().loadLeaderboard(
            gymId: widget.gymId,
            deviceId: widget.deviceId,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<RankProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Rangliste')),
      body: prov.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: prov.leaderboard.length,
              itemBuilder: (_, idx) {
                final entry = prov.leaderboard[idx];
                return ListTile(
                  leading: Text('#${idx + 1}'),
                  title: Text(entry.key),
                  trailing: Text('${entry.value.xp} XP'),
                );
              },
            ),
    );
  }
}

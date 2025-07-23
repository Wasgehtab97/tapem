import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/xp_provider.dart';
import '../../../../core/providers/muscle_group_provider.dart';
import '../../../muscle_group/domain/models/muscle_group.dart';

class XpOverviewScreen extends StatefulWidget {
  const XpOverviewScreen({Key? key}) : super(key: key);

  @override
  State<XpOverviewScreen> createState() => _XpOverviewScreenState();
}

class _XpOverviewScreenState extends State<XpOverviewScreen> {
  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    final xpProv = context.read<XpProvider>();
    final muscleProv = context.read<MuscleGroupProvider>();
    final uid = auth.userId;
    if (uid != null) {
      xpProv.watchDayXp(uid, DateTime.now());
      xpProv.watchMuscleXp(uid);
      muscleProv.loadGroups(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final xpProv = context.watch<XpProvider>();
    final muscleProv = context.watch<MuscleGroupProvider>();

    final regionXp = <MuscleRegion, int>{};
    for (final entry in xpProv.muscleXp.entries) {
      final group = muscleProv.groups
          .firstWhereOrNull((g) => g.id == entry.key);
      if (group != null) {
        regionXp[group.region] =
            (regionXp[group.region] ?? 0) + entry.value;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('XP Muskelgruppen')),
      body: ListView(
        children: [
          for (final region in MuscleRegion.values)
            ListTile(
              title: Text(region.name),
              trailing: Text('${regionXp[region] ?? 0} XP'),
            ),
        ],
      ),
    );
  }
}

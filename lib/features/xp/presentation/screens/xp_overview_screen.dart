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
    final gymId = auth.gymCode;
    if (uid != null && gymId != null) {
      debugPrint('👀 overview watchDayXp/watchMuscleXp userId=$uid');
      xpProv.watchDayXp(uid, DateTime.now());
      xpProv.watchMuscleXp(gymId, uid);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        muscleProv.loadGroups(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final xpProv = context.watch<XpProvider>();
    final muscleProv = context.watch<MuscleGroupProvider>();

    final regionXp = <MuscleRegion, int>{};
    for (final entry in xpProv.muscleXp.entries) {
      debugPrint('📊 xpEntry ${entry.key} -> ${entry.value}');
      MuscleRegion? region;
      final group =
          muscleProv.groups.firstWhereOrNull((g) => g.id == entry.key);
      if (group != null) {
        region = group.region;
        debugPrint('↪ matched group ${group.name} (${group.id}) '
            '-> region ${region.name}');
      } else {
        region = MuscleRegion.values
            .firstWhereOrNull((r) => r.name == entry.key);
        if (region != null) {
          debugPrint('↪ interpreted key ${entry.key} as region ${region.name}');
        } else {
          debugPrint('⚠️ could not map key ${entry.key} to a region');
        }
      }

      if (region != null) {
        regionXp[region] = (regionXp[region] ?? 0) + entry.value;
      }
    }

    debugPrint('💡 regionXp map: $regionXp');

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

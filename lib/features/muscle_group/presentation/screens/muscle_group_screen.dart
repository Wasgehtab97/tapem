import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/muscle_group_provider.dart';
import '../widgets/svg_muscle_heatmap_widget.dart';
import '../../domain/models/muscle_group.dart';

class MuscleGroupScreen extends StatefulWidget {
  const MuscleGroupScreen({Key? key}) : super(key: key);

  @override
  State<MuscleGroupScreen> createState() => _MuscleGroupScreenState();
}

class _MuscleGroupScreenState extends State<MuscleGroupScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MuscleGroupProvider>().loadGroups(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<MuscleGroupProvider>();

    if (prov.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (prov.error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Muskelgruppen')),
        body: Center(child: Text(prov.error!)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Muskelgruppen')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Builder(builder: (context) {
          final counts = prov.counts;
          final groups = prov.groups;
          final regionXp = <MuscleRegion, double>{};
          for (final g in groups) {
            final count = counts[g.id] ?? 0;
            regionXp[g.region] = (regionXp[g.region] ?? 0) + count.toDouble();
          }

          final xpMap = <String, double>{
            'head': 0,
            'chest': regionXp[MuscleRegion.chest] ?? 0,
            'core': regionXp[MuscleRegion.core] ?? 0,
            'pelvis': regionXp[MuscleRegion.core] ?? 0,
            'upper_arm_left': regionXp[MuscleRegion.arms] ?? 0,
            'upper_arm_right': regionXp[MuscleRegion.arms] ?? 0,
            'forearm_left': regionXp[MuscleRegion.arms] ?? 0,
            'forearm_right': regionXp[MuscleRegion.arms] ?? 0,
            'thigh_left': regionXp[MuscleRegion.legs] ?? 0,
            'thigh_right': regionXp[MuscleRegion.legs] ?? 0,
            'calf_left': regionXp[MuscleRegion.legs] ?? 0,
            'calf_right': regionXp[MuscleRegion.legs] ?? 0,
            'foot_left': regionXp[MuscleRegion.legs] ?? 0,
            'foot_right': regionXp[MuscleRegion.legs] ?? 0,
          };

          return SvgMuscleHeatmapWidget(
            xpMap: xpMap,
          );
        }),
      ),
    );
  }
}

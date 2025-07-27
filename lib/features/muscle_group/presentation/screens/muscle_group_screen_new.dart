import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/muscle_group_provider.dart';
import '../widgets/svg_muscle_heatmap_widget.dart';
import '../../domain/models/muscle_group.dart';

/// A revised muscle group screen that displays a granular 2D heatmap instead of
/// the previous rudimentary visualisation. The heatmap colours each muscle
/// region according to the normalised training count and follows the
/// mint→turquoise→amber gradient. Hover or tap interactions can be added
/// later via tooltips.
class MuscleGroupScreenNew extends StatefulWidget {
  const MuscleGroupScreenNew({Key? key}) : super(key: key);

  @override
  State<MuscleGroupScreenNew> createState() => _MuscleGroupScreenNewState();
}

class _MuscleGroupScreenNewState extends State<MuscleGroupScreenNew> {
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

    // Sum all logged counts per region.
    final Map<MuscleRegion, double> regionXp = {};
    final counts = prov.counts;
    final groups = prov.groups;
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

    return Scaffold(
      appBar: AppBar(title: const Text('Muskelgruppen')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SvgMuscleHeatmapWidget(
          xpMap: xpMap,
        ),
      ),
    );
  }
}


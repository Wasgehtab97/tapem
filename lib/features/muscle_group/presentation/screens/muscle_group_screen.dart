import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/muscle_group_provider.dart';
import '../widgets/svg_muscle_heatmap_widget.dart';
import '../widgets/mesh_3d_heatmap_widget.dart';
import '../../domain/models/muscle_group.dart';

const Map<String, List<String>> muscleCategoryMap = {
  'chest': ['pectoral'],
  'back': ['latissimus_dorsi', 'lower_back', 'rhomboids'],
  'arms': ['biceps', 'triceps', 'forearm'],
  'legs': [
    'quadriceps',
    'hamstrings',
    'adductors',
    'abductors',
    'calves',
    'feet',
  ],
  'core': ['abs'],
  'shoulders': [
    'anterior_deltoid',
    'lateral_deltoid',
    'posterior_deltoid',
    'trapezius',
  ],
};

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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
        child: Builder(
          builder: (context) {
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
              'core': (regionXp[MuscleRegion.rectusAbdominis] ?? 0) +
                  (regionXp[MuscleRegion.obliques] ?? 0) +
                  (regionXp[MuscleRegion.transversusAbdominis] ?? 0),
              'pelvis': regionXp[MuscleRegion.glutes] ?? 0,
              'upper_arm_left': regionXp[MuscleRegion.biceps] ?? 0,
              'upper_arm_right': regionXp[MuscleRegion.triceps] ?? 0,
              'forearm_left': regionXp[MuscleRegion.wristFlexors] ?? 0,
              'forearm_right': regionXp[MuscleRegion.wristFlexors] ?? 0,
              'thigh_left': regionXp[MuscleRegion.quadriceps] ?? 0,
              'thigh_right': regionXp[MuscleRegion.hamstrings] ?? 0,
              'calf_left': regionXp[MuscleRegion.calves] ?? 0,
              'calf_right': regionXp[MuscleRegion.calves] ?? 0,
              'foot_left': regionXp[MuscleRegion.tibialisAnterior] ?? 0,
              'foot_right': regionXp[MuscleRegion.tibialisAnterior] ?? 0,
            };

            final values = xpMap.values;
            final minXp = values.isNotEmpty ? values.reduce(math.min) : 0.0;
            final maxXp = values.isNotEmpty ? values.reduce(math.max) : 0.0;
            const mintColor = Color(0xFF00E676);
            const amberColor = Color(0xFFFFC107);
            final colorMap = <String, Color>{};
            xpMap.forEach((id, xp) {
              final t =
                  maxXp > minXp
                      ? ((xp - minXp) / (maxXp - minXp)).clamp(0.0, 1.0)
                      : 0.0;
              colorMap[id] = Color.lerp(mintColor, amberColor, t)!;
            });

            return DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(tabs: [Tab(text: '2D'), Tab(text: '3D')]),
                  Expanded(
                    child: TabBarView(
                      children: [
                        SvgMuscleHeatmapWidget(colors: colorMap),
                        Mesh3DHeatmapWidget(muscleColors: colorMap),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

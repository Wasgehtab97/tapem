import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';

import '../../../../core/providers/muscle_group_provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/xp_provider.dart';
import '../widgets/interactive_svg_muscle_heatmap_widget.dart';
import '../widgets/mesh_3d_heatmap_widget.dart';
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
  bool showFront = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final muscleProv = context.read<MuscleGroupProvider>();
      final auth = context.read<AuthProvider>();
      final xpProv = context.read<XpProvider>();
      muscleProv.loadGroups(context);
      final uid = auth.userId;
      final gym = auth.gymCode;
      if (uid != null && gym != null) {
        xpProv.watchMuscleXp(gym, uid);
      }
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

    final xpProv = context.watch<XpProvider>();

    // Map XP data from the provider to the corresponding muscle regions.
    final Map<MuscleRegion, int> regionXp = {};
    final groups = prov.groups;
    for (final entry in xpProv.muscleXp.entries) {
      MuscleRegion? region;
      final grp = groups.firstWhereOrNull((g) => g.id == entry.key);
      if (grp != null) {
        region = grp.region;
      } else {
        region = MuscleRegion.values.firstWhereOrNull(
          (r) => r.name == entry.key,
        );
      }
      if (region != null) {
        regionXp[region] = (regionXp[region] ?? 0) + entry.value;
      }
    }

    final xpMap = <String, int>{
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

    final values = xpMap.values.map((e) => e.toDouble());
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

    void showXp(String regionId) {
      final xp = xpMap[regionId] ?? 0;
      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: Text(regionId.replaceAll('_', ' ')),
              content: Text('$xp XP'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Muskelgruppen')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              const TabBar(tabs: [Tab(text: '2D'), Tab(text: '3D')]),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => setState(() => showFront = true),
                    child: Text(
                      'Front',
                      style: TextStyle(
                        color: showFront ? Colors.green : Colors.grey,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => showFront = false),
                    child: Text(
                      'Back',
                      style: TextStyle(
                        color: !showFront ? Colors.green : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    Center(
                      child: InteractiveSvgMuscleHeatmapWidget(
                        colors: colorMap,
                        assetPath:
                            showFront
                                ? 'assets/body_front.svg'
                                : 'assets/body_back.svg',
                        onRegionTap: showXp,
                      ),
                    ),
                    Mesh3DHeatmapWidget(muscleColors: colorMap),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

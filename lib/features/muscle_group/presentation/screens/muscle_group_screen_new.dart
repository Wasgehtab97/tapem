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

    // Compute intensities: take the maximum count per region and normalise.
    final Map<MuscleRegion, double> intensities = {};
    final counts = prov.counts;
    final groups = prov.groups;
    final int maxCount = counts.values.isEmpty
        ? 0
        : counts.values.reduce((a, b) => a > b ? a : b);
    if (maxCount > 0) {
      for (final g in groups) {
        final count = counts[g.id] ?? 0;
        final double intensity = count / maxCount;
        final existing = intensities[g.region];
        if (existing == null || intensity > existing) {
          intensities[g.region] = intensity;
        }
      }
    }

    Color gradient(double value) {
      const muted = Color(0xFF555555);
      const mint = Color(0xFF00E676);
      const turquoise = Color(0xFF00BCD4);
      const amber = Color(0xFFFFC107);
      if (value <= 0.0) return muted;
      if (value <= 0.5) {
        final t = value / 0.5;
        return Color.lerp(muted, mint, t)!;
      } else if (value <= 0.8) {
        final t = (value - 0.5) / 0.3;
        return Color.lerp(mint, turquoise, t)!;
      } else {
        final t = (value - 0.8) / 0.2;
        return Color.lerp(turquoise, amber, t.clamp(0.0, 1.0))!;
      }
    }

    final colors = <String, Color>{
      'head': const Color(0xFF555555),
      'chest': gradient(intensities[MuscleRegion.chest] ?? 0),
      'core': gradient(intensities[MuscleRegion.core] ?? 0),
      'pelvis': gradient(intensities[MuscleRegion.core] ?? 0),
      'upper_arm_left': gradient(intensities[MuscleRegion.arms] ?? 0),
      'upper_arm_right': gradient(intensities[MuscleRegion.arms] ?? 0),
      'forearm_left': gradient(intensities[MuscleRegion.arms] ?? 0),
      'forearm_right': gradient(intensities[MuscleRegion.arms] ?? 0),
      'thigh_left': gradient(intensities[MuscleRegion.legs] ?? 0),
      'thigh_right': gradient(intensities[MuscleRegion.legs] ?? 0),
      'calf_left': gradient(intensities[MuscleRegion.legs] ?? 0),
      'calf_right': gradient(intensities[MuscleRegion.legs] ?? 0),
      'foot_left': gradient(intensities[MuscleRegion.legs] ?? 0),
      'foot_right': gradient(intensities[MuscleRegion.legs] ?? 0),
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Muskelgruppen')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SvgMuscleHeatmapWidget(
          colors: colors,
          assetPath: 'assets/muscle_heatmap_optimized.svg',
        ),
      ),
    );
  }
}


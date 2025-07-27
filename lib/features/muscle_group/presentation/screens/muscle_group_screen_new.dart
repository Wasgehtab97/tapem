import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/muscle_group_provider.dart';
import '../widgets/body_heatmap_widget.dart';
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

    return Scaffold(
      appBar: AppBar(title: const Text('Muskelgruppen')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: BodyHeatmapWidget(intensities: intensities),
      ),
    );
  }
}


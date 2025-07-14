import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/muscle_group_provider.dart';

class BodyHeatmap extends StatelessWidget {
  const BodyHeatmap({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<MuscleGroupProvider>();

    final maxCount = prov.counts.values.isEmpty
        ? 0
        : prov.counts.values.reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: prov.groups.map((g) {
        final count = prov.counts[g.id] ?? 0;
        final intensity = maxCount > 0 ? count / maxCount : 0.0;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(child: Text(g.name)),
              Expanded(
                flex: 3,
                child: LinearProgressIndicator(value: intensity),
              ),
              const SizedBox(width: 8),
              Text(count.toString()),
            ],
          ),
        );
      }).toList(),
    );
  }
}

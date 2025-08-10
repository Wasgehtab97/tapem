import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/feature_flags.dart';
import '../../../../core/providers/device_provider.dart';

/// Table style component for session set input on the device page.
class SessionSetsTable extends StatelessWidget {
  const SessionSetsTable({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<DeviceProvider>();
    final previous = prov.lastSessionSets;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SessionSetsHeader(),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: prov.sets.length,
            itemBuilder: (context, index) {
              final set = prov.sets[index];
              final prev = index < previous.length
                  ? "${previous[index]['weight']} x ${previous[index]['reps']}"
                  : '—';
              return _SessionSetRow(
                index: index,
                set: set,
                previous: prev,
              );
            },
          ),
        ),
        TextButton(
          onPressed: prov.addSet,
          child: const Text('Add Set +'),
        ),
      ],
    );
  }
}

class _SessionSetsHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: const Row(
        children: [
          Expanded(child: Text('SET')),
          Expanded(child: Text('PREVIOUS')),
          Expanded(child: Text('KGS')),
          Expanded(child: Text('REPS')),
          SizedBox(width: 40, child: Text('✓')),
        ],
      ),
    );
  }
}

class _SessionSetRow extends StatelessWidget {
  final int index;
  final Map<String, String> set;
  final String previous;

  const _SessionSetRow({
    required this.index,
    required this.set,
    required this.previous,
  });

  @override
  Widget build(BuildContext context) {
    final prov = context.read<DeviceProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text('${index + 1}')),
          Expanded(child: Text(previous)),
          Expanded(
            child: TextFormField(
              initialValue: set['weight'],
              decoration: const InputDecoration(isDense: true),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (v) => prov.updateSet(index, weight: v),
            ),
          ),
          Expanded(
            child: TextFormField(
              initialValue: set['reps'],
              decoration: const InputDecoration(isDense: true),
              keyboardType: TextInputType.number,
              onChanged: (v) => prov.updateSet(index, reps: v),
            ),
          ),
          SizedBox(
            width: 40,
            child: Checkbox(
              value: false,
              onChanged: (_) {},
            ),
          ),
        ],
      ),
    );
  }
}

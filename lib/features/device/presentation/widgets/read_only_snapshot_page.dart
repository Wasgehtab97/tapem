import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tapem/features/device/domain/models/device_session_snapshot.dart';
import 'set_card.dart';
import 'package:tapem/core/widgets/brand_gradient_card.dart';

class ReadOnlySnapshotPage extends StatelessWidget {
  final DeviceSessionSnapshot snapshot;
  const ReadOnlySnapshotPage({super.key, required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd.MM.yyyy HH:mm').format(snapshot.createdAt);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(dateStr, style: const TextStyle(fontWeight: FontWeight.bold)),
              if (snapshot.note != null && snapshot.note!.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(Icons.note, size: 16),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: snapshot.sets.length,
            itemBuilder: (context, i) {
              final s = snapshot.sets[i];
              return SetCard(
                index: i,
                set: {
                  'number': '${i + 1}',
                  'weight': s.kg.toString(),
                  'reps': s.reps.toString(),
                  'rir': s.rir?.toString() ?? '',
                  'note': s.note,
                  'dropWeight': s.drops.isNotEmpty
                      ? s.drops.first.kg.toString()
                      : '',
                  'dropReps': s.drops.isNotEmpty
                      ? s.drops.first.reps.toString()
                      : '',
                  'done': s.done,
                },
                readOnly: true,
                size: SetCardSize.dense,
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 8),
          ),
        ),
        if (snapshot.note != null && snapshot.note!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: BrandGradientCard(
              padding: const EdgeInsets.all(12),
              child: Text(snapshot.note!),
            ),
          ),
      ],
    );
  }
}

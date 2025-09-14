import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tapem/features/device/domain/models/device_session_snapshot.dart';
import 'set_card.dart';
import 'package:tapem/core/widgets/brand_gradient_card.dart';
import 'package:tapem/l10n/app_localizations.dart';

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
              final isCardio = s.speedKmH != null || s.durationSec != null;
              if (isCardio) {
                return SetCard(
                  index: i,
                  set: {
                    'number': '${i + 1}',
                    'speed': s.speedKmH?.toString() ?? '',
                    'duration': s.durationSec?.toString() ?? '',
                    'done': s.done,
                  },
                  readOnly: true,
                  size: SetCardSize.dense,
                );
              }
              final drops = s.drops.isNotEmpty ? s.drops : _legacyDrops(snapshot, i);
              final loc = AppLocalizations.of(context)!;
              final weightText = s.isBodyweight
                  ? ((s.kg ?? 0) == 0
                      ? loc.bodyweight
                      : loc.bodyweightPlus(s.kg ?? 0))
                  : (s.kg?.toString() ?? '0');
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SetCard(
                    index: i,
                    set: {
                      'number': '${i + 1}',
                      'weight': weightText,
                      'reps': s.reps?.toString() ?? '0',
                      'dropWeight': '',
                      'dropReps': '',
                      'done': s.done,
                      'isBodyweight': s.isBodyweight,
                    },
                    readOnly: true,
                    size: SetCardSize.dense,
                  ),
                  if (drops.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0, top: 6),
                      child: Column(
                        children: [
                          for (final d in drops) _MiniSetCardDrop(d),
                        ],
                      ),
                    ),
                ],
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

  List<DropEntry> _legacyDrops(DeviceSessionSnapshot snap, int setIndex) {
    final hint = snap.uiHints?['legacyDrops'] as List<dynamic>?;
    if (hint == null) return const [];
    for (final e in hint) {
      final map = Map<String, dynamic>.from(e);
      if (map['set'] == setIndex) {
        final list = (map['drops'] as List<dynamic>? ?? [])
            .map((d) => DropEntry.fromJson(Map<String, dynamic>.from(d)))
            .toList();
        return list;
      }
    }
    return const [];
  }
}

class _MiniSetCardDrop extends StatelessWidget {
  final DropEntry d;
  const _MiniSetCardDrop(this.d);
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [
            Colors.deepPurple.withOpacity(0.22),
            Colors.pink.withOpacity(0.18),
          ],
        ),
        border: Border.all(color: Colors.white12, width: 0.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.south_east, size: 14),
          const SizedBox(width: 8),
          Text('${d.kg} kg',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const Spacer(),
          Text('${d.reps} ×',
              style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()])),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:tapem/core/widgets/brand_outline.dart';
import 'package:tapem/core/util/duration_utils.dart';
import '../../domain/models/session.dart';

class CardioSessionCard extends StatelessWidget {
  final Session session;
  const CardioSessionCard({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final duration = formatHms(session.durationSec ?? 0);
    Widget body;
    switch (session.mode) {
      case 'steady':
        final sp = (session.speedKmH ?? 0).toStringAsFixed(1);
        body = Text('$sp km/h • $duration', style: const TextStyle(fontSize: 14));
        break;
      case 'intervals':
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Intervalle (Gesamt $duration)',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            for (final i in session.intervals ?? [])
              Text('${_ms(i.durationSec)} @ ${(i.speedKmH ?? 0).toStringAsFixed(1)} km/h',
                  style: const TextStyle(fontSize: 14)),
          ],
        );
        break;
      default:
        body = Text('Zeit $duration', style: const TextStyle(fontSize: 14));
    }
    return BrandOutline(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            session.deviceName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          if (session.deviceDescription.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(session.deviceDescription, style: const TextStyle(fontSize: 14)),
          ],
          const SizedBox(height: 8),
          body,
        ],
      ),
    );
  }

  String _ms(int? sec) {
    final s = sec ?? 0;
    final m = s ~/ 60;
    final r = s % 60;
    return '${m.toString().padLeft(2, '0')}:${r.toString().padLeft(2, '0')}';
  }
}

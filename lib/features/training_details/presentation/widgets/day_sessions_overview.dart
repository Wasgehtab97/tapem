import 'package:flutter/material.dart';
import '../../domain/models/session.dart';

class DaySessionsOverview extends StatelessWidget {
  final List<Session> sessions;
  const DaySessionsOverview({Key? key, required this.sessions}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Limit to a maximum of two columns to avoid layout overflow on small screens
    final int columns =
        sessions.length <= 2 ? sessions.length : 2;
    return LayoutBuilder(
      builder: (context, constraints) {
        final double cardWidth =
            (constraints.maxWidth - (columns - 1) * 12) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: sessions.map((session) {
            return SizedBox(
              width: cardWidth,
              child: _buildCard(context, session),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildCard(BuildContext context, Session session) {
    return Card(
      color: const Color(0xFF1E1E1E),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              session.deviceName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            for (final set in session.sets)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  children: [
                    const Icon(Icons.fitness_center,
                        color: Color(0xFF00E676), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${set.weight.toStringAsFixed(1)} kg',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.repeat,
                        color: Color(0xFF00BCD4), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${set.reps} Wdh',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

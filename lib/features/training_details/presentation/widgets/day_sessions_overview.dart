import 'package:flutter/material.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import '../../domain/models/session.dart';

class DaySessionsOverview extends StatelessWidget {
  final List<Session> sessions;
  const DaySessionsOverview({Key? key, required this.sessions})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Limit to a maximum of two columns to avoid layout overflow on small screens
    final int columns = sessions.length <= 2 ? sessions.length : 2;
    return LayoutBuilder(
      builder: (context, constraints) {
        final double cardWidth =
            (constraints.maxWidth - (columns - 1) * 12) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children:
              sessions.map((session) {
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
    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.brandGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              session.deviceName,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
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
                    Icon(
                      Icons.fitness_center,
                      color: Theme.of(context).colorScheme.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${set.weight.toStringAsFixed(1)} kg',
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimary
                            .withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.repeat,
                      color: Theme.of(context).colorScheme.secondary,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${set.reps} Wdh',
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimary
                            .withOpacity(0.7),
                        fontSize: 14,
                      ),
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

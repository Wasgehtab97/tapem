import 'package:flutter/material.dart';
import 'package:tapem/core/widgets/brand_gradient_card.dart';
import '../../domain/models/session.dart';

/// A reusable card displaying a session's sets for a single device/exercise.
class SessionExerciseCard extends StatelessWidget {
  final String deviceName;
  final List<SessionSet> sets;
  final EdgeInsetsGeometry padding;

  const SessionExerciseCard({
    Key? key,
    required this.deviceName,
    required this.sets,
    this.padding = const EdgeInsets.all(12.0),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BrandGradientCard(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            deviceName,
            style: TextStyle(
              color: theme.colorScheme.onPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          for (final set in sets)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Row(
                children: [
                  Icon(
                    Icons.fitness_center,
                    color: theme.colorScheme.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${set.weight.toStringAsFixed(1)} kg',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.repeat,
                    color: theme.colorScheme.secondary,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${set.reps} Wdh',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:tapem/core/widgets/brand_gradient_card.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import '../../domain/models/session.dart';

/// A reusable card displaying a session's sets for a single device/exercise.
class SessionExerciseCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<SessionSet> sets;
  final EdgeInsetsGeometry padding;

  const SessionExerciseCard({
    Key? key,
    required this.title,
    this.subtitle,
    required this.sets,
    this.padding = const EdgeInsets.all(12.0),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final onBrand =
        Theme.of(context).extension<AppBrandTheme>()?.onBrand ?? Colors.white;
    return BrandGradientCard(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: TextStyle(
                color: onBrand.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
          const SizedBox(height: 8),
          for (final set in sets)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.fitness_center,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${set.weight.toStringAsFixed(1)} kg',
                        style: TextStyle(
                          color: onBrand.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.repeat,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${set.reps} Wdh',
                        style: TextStyle(
                          color: onBrand.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  for (final drop in set.dropSets)
                    Padding(
                      padding: const EdgeInsets.only(left: 20, top: 2),
                      child: Text(
                        '↘︎ ${drop.weightKg.toStringAsFixed(1)} kg × ${drop.reps}',
                        style: TextStyle(
                          color: onBrand.withOpacity(0.6),
                          fontSize: 12,
                        ),
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


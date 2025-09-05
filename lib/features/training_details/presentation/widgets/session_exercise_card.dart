import 'package:flutter/material.dart';
import 'package:tapem/core/widgets/brand_gradient_card.dart';
import 'package:tapem/core/theme/brand_on_colors.dart';
import '../../domain/models/session.dart';
import 'package:tapem/l10n/app_localizations.dart';

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
        Theme.of(context).extension<BrandOnColors>()?.onGradient ?? Colors.black;
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
                color: onBrand,
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
                      Builder(builder: (context) {
                        final loc = AppLocalizations.of(context)!;
                        final wt = set.isBodyweight
                            ? (set.weight == 0
                                ? loc.bodyweight
                                : loc.bodyweightPlus(
                                    set.weight.toStringAsFixed(1)))
                            : '${set.weight.toStringAsFixed(1)} kg';
                        return Text(
                          wt,
                          style: TextStyle(
                            color: onBrand,
                            fontSize: 14,
                          ),
                        );
                      }),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.repeat,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${set.reps} Wdh',
                        style: TextStyle(
                          color: onBrand,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  if (set.dropWeightKg != null && set.dropReps != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 20, top: 2),
                      child: Text(
                        '↘︎ ${set.dropWeightKg!.toStringAsFixed(1)} kg × ${set.dropReps}',
                        style: TextStyle(
                          color: onBrand,
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


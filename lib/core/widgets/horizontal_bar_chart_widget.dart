import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// Displays a horizontal segmented bar chart.
///
/// Each entry represents a category (e.g. device usage). The `values`
/// determine the relative lengths of the segments. Colours are mapped
/// automatically: high values → mint, medium → turquoise, low → amber.
class HorizontalBarChart extends StatelessWidget {
  const HorizontalBarChart({
    Key? key,
    required this.data,
    this.barHeight = 24,
    this.maxValue,
  }) : super(key: key);

  /// Map of label to numeric value.
  final Map<String, double> data;

  /// Height of each bar.
  final double barHeight;

  /// Optional maximum value used to normalise bar lengths. If null, the
  /// largest value in `data` will be used.
  final double? maxValue;

  Color _getColour(double value, double max) {
    final ratio = value / max;
    if (ratio > 0.66) return AppColors.accentMint;
    if (ratio > 0.33) return AppColors.accentTurquoise;
    return AppColors.accentAmber;
  }

  @override
  Widget build(BuildContext context) {
    final maxVal = maxValue ?? (data.values.isEmpty ? 1 : data.values.reduce((a, b) => a > b ? a : b));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: data.entries.map((entry) {
        final ratio = (entry.value / maxVal).clamp(0.0, 1.0);
        final colour = _getColour(entry.value, maxVal);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs / 2),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  entry.key,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: barHeight,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.button),
                      ),
                    ),
                    AnimatedContainer(
                      duration: AppDurations.short,
                      height: barHeight,
                      width: ratio * 1.0,
                      decoration: BoxDecoration(
                        color: colour,
                        borderRadius: BorderRadius.circular(AppRadius.button),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                entry.value.toStringAsFixed(0),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

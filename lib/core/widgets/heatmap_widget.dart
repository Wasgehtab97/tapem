import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// A simple heatmap widget rendering a 2D grid of squares.
///
/// The `values` matrix holds intensity values between 0 and 1. Colours are
/// interpolated between the mint, turquoise and amber accents. When a cell
/// is tapped, the `onCellTap` callback is invoked with its row and column
/// indices and value.
class HeatmapWidget extends StatelessWidget {
  const HeatmapWidget({
    Key? key,
    required this.values,
    this.cellSize = 24,
    this.onCellTap,
  }) : super(key: key);

  /// A 2D list of values between 0 and 1 representing heat intensities.
  final List<List<double>> values;

  /// Size of each square cell in logical pixels.
  final double cellSize;

  /// Optional callback when a cell is tapped.
  final void Function(int row, int col, double value)? onCellTap;

  Color _getColour(double value) {
    // Map value to gradient: 0→amber, 0.5→turquoise, 1→mint
    if (value >= 0.66) return AppColors.accentMint;
    if (value >= 0.33) return AppColors.accentTurquoise;
    return AppColors.accentAmber;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < values.length; i++)
          Row(
            children: [
              for (int j = 0; j < values[i].length; j++)
                GestureDetector(
                  onTap: onCellTap == null ? null : () => onCellTap!(i, j, values[i][j]),
                  child: Container(
                    width: cellSize,
                    height: cellSize,
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: _getColour(values[i][j]),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:tapem/core/theme/design_tokens.dart';

/// A circular XP gauge that animates from 0 to the provided XP value.
///
/// One full revolution (360°) corresponds to 1000 XP and therefore one level.
/// The gauge changes colour depending on how close the user is to the next
/// level: mint for low progress, turquoise for medium progress and amber for
/// high progress. A central label shows the current level, total XP and an
/// optional description (e.g. muscle name or device name).
class XpGauge extends StatelessWidget {
  /// The current XP value for this gauge.
  final int currentXp;

  /// The current level of the user. A level is reached every 1000 XP.
  final int level;

  /// A label displayed underneath the XP value (e.g. muscle group or day).
  final String label;

  /// The diameter of the gauge in logical pixels.
  final double size;

  /// Optional callback triggered when the gauge is tapped. Can be used to
  /// navigate to a detail or leaderboard page.
  final VoidCallback? onTap;

  const XpGauge({
    Key? key,
    required this.currentXp,
    required this.level,
    required this.label,
    this.size = 120.0,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculate the fractional progress towards the next level.
    final double progress = (currentXp % 1000) / 1000.0;

    // Helper to determine the colour at the current progress.
    Color progressColor(double value) {
      final colors = AppGradients.brandGradient.colors;
      if (colors.length == 1) return colors.first;
      if (value <= 0.5) {
        return colors.first;
      } else {
        return colors.last;
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // The circular progress bar.
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                strokeWidth: size * 0.08,
                valueColor: AlwaysStoppedAnimation<Color>(
                  progressColor(progress),
                ),
                backgroundColor:
                    Theme.of(context).colorScheme.onPrimary.withOpacity(0.2),
              ),
            ),
            // The label text in the centre of the gauge.
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Lv. $level',
                  style: TextStyle(
                    fontSize: size * 0.22,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                Text(
                  '$currentXp XP',
                  style: TextStyle(
                    fontSize: size * 0.14,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: size * 0.12,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// lib/presentation/widgets/training_plan/streak_badge.dart

import 'package:flutter/material.dart';
import 'dart:math';

/// Ein kreisförmiges Badge, das die aktuelle Trainings-Streak
/// als Flammen-Icon plus Zahl sowie einen Fortschrittsring anzeigt.
class StreakBadge extends StatelessWidget {
  /// Anzahl aufeinanderfolgender Trainingstage.
  final int streak;

  /// Durchmesser des Badges in Pixeln.
  final double size;

  /// Optional: Callback bei Tap auf das Badge.
  final VoidCallback? onPressed;

  const StreakBadge({
    Key? key,
    required this.streak,
    this.size = 60,
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final borderColor = Theme.of(context).dividerColor;
    final iconColor = Colors.deepOrange;
    final textStyle = Theme.of(context)
        .textTheme
        .bodyLarge
        ?.copyWith(fontSize: size * 0.33, fontWeight: FontWeight.bold);

    Widget badge = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.local_fire_department, size: size * 0.8, color: iconColor),
          Text(streak.toString(), style: textStyle),
        ],
      ),
    );

    if (onPressed != null) {
      badge = InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(size / 2),
        child: badge,
      );
    }

    return badge;
  }
}

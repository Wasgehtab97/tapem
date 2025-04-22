import 'package:flutter/material.dart';

class StreakBadge extends StatelessWidget {
  final int streak;
  final double size;

  const StreakBadge({
    Key? key,
    required this.streak,
    this.size = 60,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Hier wird die Farbe des Rahmens über das aktuelle Theme bezogen.
    final Color borderColor = Theme.of(context).dividerColor;
    // Für das Icon verwenden wir ein feuriges Orange, was gut zu "Streak" (Flamme) passt.
    final Color iconColor = Colors.deepOrange;
    // Der Textstil wird an die Badge-Größe angepasst.
    final TextStyle? textStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
      fontSize: size * 0.33,
      fontWeight: FontWeight.bold,
    );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.local_fire_department,
            size: size * 0.8,
            color: iconColor,
          ),
          Text(
            streak.toString(),
            style: textStyle,
          ),
        ],
      ),
    );
  }
}

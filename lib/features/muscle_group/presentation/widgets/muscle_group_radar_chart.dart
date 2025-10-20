import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Describes a single entry in the [MuscleGroupRadarChart].
class MuscleRadarEntry {
  const MuscleRadarEntry({
    required this.label,
    required this.percentage,
  });

  /// Display label rendered outside the chart.
  final String label;

  /// Normalised value in the range `[0, 1]`.
  final double percentage;
}

/// A bespoke radar chart used to visualise the distribution of XP across
/// muscle groups. The implementation deliberately avoids depending on
/// additional chart libraries so that it can be tuned precisely to the product
/// requirements (labels, grid styling, theming) without pulling in heavy
/// widgets.
class MuscleGroupRadarChart extends StatelessWidget {
  const MuscleGroupRadarChart({
    super.key,
    required this.entries,
    this.ringCount = 5,
  }) : assert(ringCount >= 1, 'ringCount must be at least 1');

  /// Data entries displayed in clockwise order starting from the top.
  final List<MuscleRadarEntry> entries;

  /// Number of concentric rings rendered in the grid.
  final int ringCount;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }

    return CustomPaint(
      painter: _RadarChartPainter(
        entries: entries,
        ringCount: ringCount,
        theme: Theme.of(context),
        textDirection: Directionality.of(context),
      ),
    );
  }
}

class _RadarChartPainter extends CustomPainter {
  _RadarChartPainter({
    required this.entries,
    required this.ringCount,
    required this.theme,
    required this.textDirection,
  });

  final List<MuscleRadarEntry> entries;
  final int ringCount;
  final ThemeData theme;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    const labelPadding = 48.0;
    final radius = math.max(
      0.0,
      math.min(size.width, size.height) / 2 - labelPadding,
    );

    if (radius <= 0 || entries.isEmpty) {
      return;
    }

    final axisColor = theme.colorScheme.outline;
    final axisPaint = Paint()
      ..color = axisColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final gridPaint = Paint()
      ..color = axisColor.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final fillPaint = Paint()
      ..color = theme.colorScheme.primary.withOpacity(0.25)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = theme.colorScheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    final entryPaint = Paint()
      ..color = theme.colorScheme.primary
      ..style = PaintingStyle.fill;

    final labelStyle = theme.textTheme.labelMedium ??
        TextStyle(
          color: theme.colorScheme.onSurface,
          fontSize: 13,
        );
    final ticksStyle = theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ) ??
        TextStyle(
          color: theme.colorScheme.onSurface.withOpacity(0.6),
          fontSize: 12,
        );

    final angleStep = (2 * math.pi) / entries.length;
    const startAngle = -math.pi / 2;

    Path ringPathForRadius(double ringRadius) {
      final path = Path();
      for (var i = 0; i < entries.length; i++) {
        final angle = startAngle + angleStep * i;
        final offset = Offset(
          center.dx + math.cos(angle) * ringRadius,
          center.dy + math.sin(angle) * ringRadius,
        );
        if (i == 0) {
          path.moveTo(offset.dx, offset.dy);
        } else {
          path.lineTo(offset.dx, offset.dy);
        }
      }
      path.close();
      return path;
    }

    // Draw concentric grid rings.
    for (var ring = 1; ring <= ringCount; ring++) {
      final ringRadius = radius * (ring / ringCount);
      final path = ringPathForRadius(ringRadius);
      canvas.drawPath(path, gridPaint);
    }

    // Draw axis lines from the centre.
    for (var i = 0; i < entries.length; i++) {
      final angle = startAngle + angleStep * i;
      final endPoint = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      canvas.drawLine(center, endPoint, axisPaint);
    }

    // Build the polygon representing the actual values.
    final dataPath = Path();
    final normalizedEntries = entries
        .map((e) => e.percentage.isFinite && !e.percentage.isNaN
            ? e.percentage.clamp(0.0, 1.0)
            : 0.0)
        .toList(growable: false);
    for (var i = 0; i < normalizedEntries.length; i++) {
      final value = normalizedEntries[i];
      final angle = startAngle + angleStep * i;
      final point = Offset(
        center.dx + math.cos(angle) * radius * value,
        center.dy + math.sin(angle) * radius * value,
      );
      if (i == 0) {
        dataPath.moveTo(point.dx, point.dy);
      } else {
        dataPath.lineTo(point.dx, point.dy);
      }
    }
    dataPath.close();

    canvas.drawPath(dataPath, fillPaint);
    canvas.drawPath(dataPath, borderPaint);

    // Draw points for each entry.
    for (var i = 0; i < normalizedEntries.length; i++) {
      final value = normalizedEntries[i];
      final angle = startAngle + angleStep * i;
      final point = Offset(
        center.dx + math.cos(angle) * radius * value,
        center.dy + math.sin(angle) * radius * value,
      );
      canvas.drawCircle(point, 4, entryPaint);
      canvas.drawCircle(
        point,
        4,
        Paint()
          ..color = theme.colorScheme.onPrimary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    // Draw tick labels along the top axis.
    final direction = textDirection;
    for (var ring = 1; ring <= ringCount; ring++) {
      final fraction = ring / ringCount;
      final label = '${(fraction * 100).round()}%';
      final position = Offset(
        center.dx,
        center.dy - radius * fraction,
      );
      final tickPainter = TextPainter(
        text: TextSpan(text: label, style: ticksStyle),
        textAlign: TextAlign.center,
        textDirection: direction,
      )..layout();
      final offset = Offset(
        position.dx - tickPainter.width / 2,
        position.dy - tickPainter.height - 4,
      );
      tickPainter.paint(canvas, offset);
    }

    // Draw labels around the chart.
    final labelRadius = radius + 20;
    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final angle = startAngle + angleStep * i;
      final position = Offset(
        center.dx + math.cos(angle) * labelRadius,
        center.dy + math.sin(angle) * labelRadius,
      );
      final percentText = '${(normalizedEntries[i] * 100).round()}%';
      final labelPainter = TextPainter(
        text: TextSpan(
          text: '${entry.label}\n$percentText',
          style: labelStyle,
        ),
        maxLines: 2,
        textAlign: TextAlign.center,
        textDirection: direction,
      )..layout(maxWidth: math.max(80, radius * 0.6));

      final dx = position.dx - labelPainter.width / 2;
      final dy = position.dy - labelPainter.height / 2;
      labelPainter.paint(canvas, Offset(dx, dy));
    }
  }

  @override
  bool shouldRepaint(covariant _RadarChartPainter oldDelegate) {
    return oldDelegate.entries != entries ||
        oldDelegate.ringCount != ringCount ||
        oldDelegate.theme != theme;
  }
}

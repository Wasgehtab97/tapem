import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';

class CalendarHeatmap extends StatelessWidget {
  final List<DateTime> dates;
  const CalendarHeatmap({required this.dates, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Tages-Counts ermitteln
    final Map<DateTime, int> counts = {};
    for (final dt in dates) {
      final day = DateTime(dt.year, dt.month, dt.day);
      counts[day] = (counts[day] ?? 0) + 1;
    }

    // Earliest date für Init
    final initDate = counts.keys.isNotEmpty
        ? counts.keys.reduce((a, b) => a.isBefore(b) ? a : b)
        : DateTime.now();

    return HeatMapCalendar(
      // Daten und Farbschwellen
      datasets: counts,
      colorsets: {
        1: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        5: Theme.of(context).colorScheme.primary.withOpacity(0.6),
        10: Theme.of(context).colorScheme.primary,
      },
      colorMode: ColorMode.opacity,
      defaultColor: Theme.of(context).colorScheme.background,
      // Layout
      initDate: initDate,
      size: 20.0,
      // Klick-Handler
      onClick: (date) {
        final count = counts[date] ?? 0;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Logs am ${date.toLocal().toIso8601String().split("T")[0]}: $count',
            ),
          ),
        );
      },
      showColorTip: false,
      flexible: true,
      margin: const EdgeInsets.symmetric(vertical: 8),
    );
  }
}

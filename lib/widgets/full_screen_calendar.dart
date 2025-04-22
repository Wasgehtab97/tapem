// lib/widgets/full_screen_calendar.dart

import 'package:flutter/material.dart';
import 'calendar.dart';
import '../screens/training_details_screen.dart';

class FullScreenCalendar extends StatelessWidget {
  final List<String> trainingDates;

  const FullScreenCalendar({
    Key? key,
    required this.trainingDates,
  }) : super(key: key);

  /// Formatiert deutsches Datum "YYYY-MM-DD".
  String _formatGermanDate(DateTime date) {
    final offset = (date.month >= 4 && date.month <= 10) ? 2 : 1;
    final d = date.toUtc().add(Duration(hours: offset));
    final y = d.year.toString();
    final m = d.month.toString().padLeft(2, '0');
    final da = d.day.toString().padLeft(2, '0');
    return "$y-$m-$da";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Kalender', style: theme.appBarTheme.titleTextStyle),
        backgroundColor: theme.appBarTheme.backgroundColor,
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Calendar(
            trainingDates: trainingDates,
            cellSize: 16.0,
            cellSpacing: 3.0,
            onDayTap: (day) {
              final f = _formatGermanDate(day);
              if (trainingDates.contains(f)) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TrainingDetailsScreen(selectedDate: f),
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}

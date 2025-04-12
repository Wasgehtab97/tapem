import 'package:flutter/material.dart';
import 'calendar.dart';
import '../screens/training_details_screen.dart';

class FullScreenCalendar extends StatelessWidget {
  final List<String> trainingDates;

  const FullScreenCalendar({Key? key, required this.trainingDates}) : super(key: key);

  /// Konvertiert ein Datum in die deutsche Zeitzone (Europe/Berlin)
  /// unter Berücksichtigung eines einfachen DST-Checks und formatiert es als "YYYY-MM-DD".
  String formatGermanDate(DateTime date) {
    int offset = (date.month > 3 && date.month < 10) ? 2 : 1;
    final germanDate = date.toUtc().add(Duration(hours: offset));
    final year = germanDate.year.toString();
    final month = germanDate.month.toString().padLeft(2, '0');
    final day = germanDate.day.toString().padLeft(2, '0');
    return "$year-$month-$day";
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
            // Beim Tippen auf einen Tag:
            onDayTap: (DateTime day) {
              String formatted = formatGermanDate(day);
              if (trainingDates.contains(formatted)) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TrainingDetailsScreen(selectedDate: formatted),
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

// lib/presentation/widgets/training_plan/full_screen_calendar.dart

import 'package:flutter/material.dart';
import 'package:tapem/presentation/widgets/common/calendar.dart';
import 'package:tapem/presentation/screens/training_details/training_details_screen.dart';

/// Zeigt einen datumsorientierten Kalender im Vollbild,
/// in dem erfasste Trainingstage markiert sind.
class FullScreenCalendar extends StatelessWidget {
  /// Liste der Trainingstage im Format "YYYY-MM-DD".
  final List<String> trainingDates;

  const FullScreenCalendar({
    Key? key,
    required this.trainingDates,
  }) : super(key: key);

  String _formatGermanDate(DateTime date) {
    // Bei Sommerzeit UTC+2, sonst UTC+1
    final offset = (date.month >= 4 && date.month <= 10) ? 2 : 1;
    final d = date.toUtc().add(Duration(hours: offset));
    final y = d.year.toString();
    final m = d.month.toString().padLeft(2, '0');
    final da = d.day.toString().padLeft(2, '0');
    return '$y-$m-$da';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kalender')),
      body: Semantics(
        label: 'Vollbild-Kalender',
        child: Center(
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
      ),
    );
  }
}

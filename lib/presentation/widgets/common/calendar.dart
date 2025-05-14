// lib/presentation/widgets/common/calendar.dart

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

/// Ein einfacher Datums-Kalender, der nur Markierungen und Tap-Callback unterstützt.
class Calendar extends StatelessWidget {
  final List<String> trainingDates;
  final double cellSize;
  final double cellSpacing;
  final void Function(DateTime day)? onDayTap;

  const Calendar({
    Key? key,
    required this.trainingDates,
    this.cellSize = 40.0,
    this.cellSpacing = 4.0,
    this.onDayTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TableCalendar(
      firstDay: DateTime.utc(2000, 1, 1),
      lastDay: DateTime.utc(2100, 12, 31),
      focusedDay: DateTime.now(),
      availableCalendarFormats: const { CalendarFormat.month: '' },
      daysOfWeekHeight: cellSize,
      rowHeight: cellSize + cellSpacing,
      headerVisible: false,
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (context, day, focusedDay) {
          final key = '${day.year}-${day.month.toString().padLeft(2,'0')}-${day.day.toString().padLeft(2,'0')}';
          final isTraining = trainingDates.contains(key);
          return GestureDetector(
            onTap: () => onDayTap?.call(day),
            child: Container(
              margin: EdgeInsets.all(cellSpacing / 2),
              width: cellSize,
              height: cellSize,
              decoration: BoxDecoration(
                color: isTraining ? Theme.of(context).colorScheme.primary : null,
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.center,
              child: Text('${day.day}', style: TextStyle(
                color: isTraining ? Colors.white : null,
                fontSize: cellSize * 0.4,
              )),
            ),
          );
        },
      ),
    );
  }
}

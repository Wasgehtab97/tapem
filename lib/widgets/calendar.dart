// lib/widgets/calendar.dart

import 'package:flutter/material.dart';

class Calendar extends StatelessWidget {
  final List<String> trainingDates;
  final double cellSize;
  final int rows;
  final double cellSpacing;
  final void Function(DateTime)? onDayTap;

  const Calendar({
    Key? key,
    required this.trainingDates,
    this.cellSize = 12.0,
    this.rows = 7,
    this.cellSpacing = 2.0,
    this.onDayTap,
  }) : super(key: key);

  /// Formatiert ein Datum als "YYYY-MM-DD".
  String _formatDate(DateTime date) {
    final y = date.year.toString();
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return "$y-$m-$d";
  }

  /// Konvertiert in deutsche Zeitzone, gibt "YYYY-MM-DD".
  String _formatGermanDate(DateTime date) {
    final offset = (date.month >= 4 && date.month <= 10) ? 2 : 1;
    return _formatDate(date.toUtc().add(Duration(hours: offset)));
  }

  /// Alle Tage des aktuellen Jahres.
  List<DateTime> _allDaysOfYear() {
    final y = DateTime.now().year;
    final first = DateTime(y, 1, 1);
    final last = DateTime(y, 12, 31);
    final count = last.difference(first).inDays + 1;
    return List.generate(count, (i) => first.add(Duration(days: i)));
  }

  bool _isTrainingDay(DateTime date) => trainingDates.contains(_formatGermanDate(date));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allDays = _allDaysOfYear();
    final offset = DateTime(allDays.first.year, 1, 1).weekday - 1;
    final cells = <DateTime?>[
      ...List<DateTime?>.filled(offset, null),
      ...allDays,
    ];
    final rem = cells.length % rows;
    if (rem != 0) cells.addAll(List<DateTime?>.filled(rows - rem, null));
    final cols = (cells.length / rows).ceil();
    final totalW = cols * (cellSize + cellSpacing);

    const months = ["J", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N", "D"];
    final header = months.map((m) => SizedBox(
          width: totalW / 12,
          child: Center(child: Text(m, style: theme.textTheme.bodySmall?.copyWith(color: Colors.white, fontSize: 8))),
        ));

    final today = _formatGermanDate(DateTime.now());
    final rowsWidgets = <TableRow>[];
    for (var r = 0; r < rows; r++) {
      final row = <Widget>[];
      for (var c = 0; c < cols; c++) {
        final idx = c * rows + r;
        Widget cell;
        if (idx < cells.length && cells[idx] != null) {
          final d = cells[idx]!;
          final isTrain = _isTrainingDay(d);
          final isTodayCell = _formatGermanDate(d) == today;
          cell = GestureDetector(
            onTap: onDayTap == null ? null : () => onDayTap!(d),
            child: Container(
              margin: EdgeInsets.all(cellSpacing / 2),
              width: cellSize,
              height: cellSize,
              decoration: BoxDecoration(
                color: isTrain ? theme.colorScheme.secondary : Colors.transparent,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  width: isTodayCell ? 1.5 : 1.0,
                  color: isTodayCell ? theme.colorScheme.error : Colors.white,
                ),
              ),
            ),
          );
        } else {
          cell = SizedBox(width: cellSize, height: cellSize);
        }
        row.add(cell);
      }
      rowsWidgets.add(TableRow(children: row));
    }

    return LayoutBuilder(builder: (_, constraints) {
      return FittedBox(
        fit: BoxFit.contain,
        child: Container(
          width: totalW,
          padding: EdgeInsets.all(cellSpacing),
          color: theme.scaffoldBackgroundColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: header.toList()),
              SizedBox(height: 4),
              Table(
                defaultColumnWidth: FixedColumnWidth(cellSize + cellSpacing),
                children: rowsWidgets,
              ),
            ],
          ),
        ),
      );
    });
  }
}

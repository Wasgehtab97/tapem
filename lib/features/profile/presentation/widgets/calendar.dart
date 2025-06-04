// lib/features/profile/presentation/widgets/calendar.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// GitHub-Style Jahres-Heatmap.
/// Klick‐Callback nur innerhalb des Popups aktiv.
class Calendar extends StatefulWidget {
  final List<String> trainingDates;
  final void Function(DateTime)? onDayTap;
  final bool showNavigation;
  final int year;

  Calendar({
    Key? key,
    required this.trainingDates,
    this.onDayTap,
    this.showNavigation = true,
    int? year,
  })  : year = year ?? DateTime.now().year,
        super(key: key);

  @override
  State<Calendar> createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  late int _year;

  @override
  void initState() {
    super.initState();
    _year = widget.year;
  }

  void _prevYear() => setState(() => _year--);
  void _nextYear() => setState(() => _year++);

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final today  = DateTime.now();

    final firstOfYear = DateTime(_year, 1, 1);
    final lastOfYear  = DateTime(_year, 12, 31);

    final startOffset = (firstOfYear.weekday + 6) % 7;
    final gridStart   = firstOfYear.subtract(Duration(days: startOffset));
    final endOffset   = 6 - ((lastOfYear.weekday + 6) % 7);
    final gridEnd     = lastOfYear.add(Duration(days: endOffset));
    final totalDays   = gridEnd.difference(gridStart).inDays + 1;
    final weekCount   = (totalDays / 7).ceil();

    return LayoutBuilder(builder: (ctx, constraints) {
      const hPad   = 16.0;
      const margin = 1.0;
      final usable = constraints.maxWidth - hPad * 2;
      final rawSize = (usable - weekCount * margin * 2) / weekCount;
      final cellSize = rawSize.clamp(4.0, usable);

      // Monats-Labels
      List<Widget> monthLabels = [];
      for (var m = 1; m <= 12; m++) {
        final firstOfMonth = DateTime(_year, m, 1);
        final offsetDays   = firstOfMonth.difference(gridStart).inDays;
        final colIndex     = (offsetDays / 7).floor().clamp(0, weekCount - 1);
        monthLabels.add(Positioned(
          left: hPad + colIndex * (cellSize + margin * 2),
          child: Text(
            DateFormat.MMM(locale).format(firstOfMonth),
            style: theme.textTheme.bodySmall,
          ),
        ));
      }

      final header = widget.showNavigation
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: hPad),
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.chevron_left, size: 20), onPressed: _prevYear),
                  Expanded(
                    child: Center(
                      child: Text(
                        '$_year',
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.chevron_right, size: 20), onPressed: _nextYear),
                ],
              ),
            )
          : const SizedBox.shrink();

      final grid = Padding(
        padding: const EdgeInsets.symmetric(horizontal: hPad),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(weekCount, (w) {
            return Column(
              children: List.generate(7, (d) {
                final date = gridStart.add(Duration(days: w * 7 + d));
                if (date.isBefore(firstOfYear) || date.isAfter(lastOfYear)) {
                  // Statt SizedBox jetzt Container mit margin
                  return Container(
                    width:  cellSize,
                    height: cellSize,
                    margin: const EdgeInsets.all(margin),
                  );
                }

                final key = DateFormat('yyyy-MM-dd').format(date);
                final isTrain = widget.trainingDates.contains(key);
                final isToday = date.year == today.year &&
                                date.month == today.month &&
                                date.day == today.day;

                Widget box = Container(
                  width:  cellSize,
                  height: cellSize,
                  margin: const EdgeInsets.all(margin),
                  decoration: BoxDecoration(
                    color: isTrain
                        ? theme.colorScheme.secondary.withOpacity(0.6)
                        : Colors.transparent,
                    border: Border.all(
                      color: isToday ? theme.colorScheme.error : theme.dividerColor,
                      width: isToday ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );

                if (widget.onDayTap != null) {
                  box = GestureDetector(
                    onTap: () => widget.onDayTap!(date),
                    child: box,
                  );
                }
                return box;
              }),
            );
          }),
        ),
      );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          SizedBox(height: 20, child: Stack(children: monthLabels)),
          const SizedBox(height: 4),
          grid,
        ],
      );
    });
  }
}

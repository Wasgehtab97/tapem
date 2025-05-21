import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// GitHub-Style Jahres-Heatmap:
/// • 7 Reihen (Mo–So), dynamische Spaltenanzahl je Wochenbedarf  
/// • Grid von Montag-Woche mit 1. Jan bis Sonntag-Woche mit 31. Dez  
/// • Monatschriftzüge oben exakt über der ersten Zelle  
/// • Trainingstage gefüllt, heutiger Tag rot umrandet  
class Calendar extends StatefulWidget {
  /// Trainingsdaten im Format "YYYY-MM-DD"
  final List<String> trainingDates;

  /// Klick-Callback für einen Tag
  final void Function(DateTime)? onDayTap;

  /// Soll die Jahres-Navigation (Pfeile) angezeigt werden?
  final bool showNavigation;

  /// Start-Jahr (default = aktuelles Jahr)
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

    // 1) Erste und letzte relevante Daten
    final firstOfYear = DateTime(_year, 1, 1);
    final lastOfYear  = DateTime(_year, 12, 31);

    // 2) Grid-Start = Montag der 1. Jan-Woche
    final startOffset = (firstOfYear.weekday + 6) % 7; // Mo→0 … So→6
    final gridStart   = firstOfYear.subtract(Duration(days: startOffset));

    // 3) Grid-Ende = Sonntag der 31. Dez-Woche
    final endOffset = 6 - ((lastOfYear.weekday + 6) % 7);
    final gridEnd   = lastOfYear.add(Duration(days: endOffset));

    // 4) Wochenanzahl
    final totalDays = gridEnd.difference(gridStart).inDays + 1;
    final weekCount = (totalDays / 7).ceil();

    // 5) Map: Woche → 7 Tage (null=außerhalb)
    final weeks = <int, List<DateTime?>>{
      for (var w = 0; w < weekCount; w++)
        w: List<DateTime?>.generate(7, (d) {
          final date = gridStart.add(Duration(days: w * 7 + d));
          return (date.isBefore(firstOfYear) || date.isAfter(lastOfYear))
              ? null
              : date;
        }),
    };

    return LayoutBuilder(builder: (ctx, constraints) {
      const hPad   = 16.0;
      const margin = 1.0;
      final usable = constraints.maxWidth - hPad * 2;
      final rawSize = (usable - weekCount * margin * 2) / weekCount;
      final cellSize = rawSize.clamp(4.0, usable);

      // 6) Monats-Labels positionieren
      final monthLabels = <Widget>[];
      for (var m = 1; m <= 12; m++) {
        final firstOfMonth = DateTime(_year, m, 1);
        final offsetDays   = firstOfMonth.difference(gridStart).inDays;
        final colIndex     =
            (offsetDays / 7).floor().clamp(0, weekCount - 1);
        final left = hPad + colIndex * (cellSize + margin * 2);

        monthLabels.add(Positioned(
          left: left,
          child: Text(
            DateFormat.MMM(locale).format(firstOfMonth),
            style: theme.textTheme.bodySmall,
          ),
        ));
      }

      // 7) optional: Header mit Pfeilen
      final header = widget.showNavigation
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: hPad),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 20),
                    onPressed: _prevYear,
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        '$_year',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 20),
                    onPressed: _nextYear,
                  ),
                ],
              ),
            )
          : const SizedBox.shrink();

      // 8) Grid rendern
      final grid = Padding(
        padding: const EdgeInsets.symmetric(horizontal: hPad),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(weekCount, (w) {
            final days = weeks[w]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(7, (d) {
                final date = days[d];
                if (date == null) {
                  return Container(
                    width:  cellSize,
                    height: cellSize,
                    margin: const EdgeInsets.all(margin),
                  );
                }
                final isToday = date.year == today.year &&
                                date.month == today.month &&
                                date.day == today.day;
                final key = '${date.year}-'
                    '${date.month.toString().padLeft(2,'0')}-'
                    '${date.day.toString().padLeft(2,'0')}';
                final isTrain = widget.trainingDates.contains(key);

                return GestureDetector(
                  onTap: widget.onDayTap == null
                      ? null
                      : () => widget.onDayTap!(date),
                  child: Container(
                    width:  cellSize,
                    height: cellSize,
                    margin: const EdgeInsets.all(margin),
                    decoration: BoxDecoration(
                      color: isTrain
                          ? theme.colorScheme.secondary.withOpacity(0.6)
                          : Colors.transparent,
                      border: Border.all(
                        color: isToday
                            ? theme.colorScheme.error
                            : theme.dividerColor,
                        width: isToday ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
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

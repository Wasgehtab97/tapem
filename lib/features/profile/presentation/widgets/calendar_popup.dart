// lib/features/profile/presentation/widgets/calendar_popup.dart

import 'package:flutter/material.dart';
import 'package:tapem/features/profile/presentation/widgets/calendar.dart';

/// Modal Bottom Sheet mit größerem, horizontal scrollbarem Jahres-Heatmap-Kalender.
/// Startet automatisch in der aktuellen Kalenderwoche.
class CalendarPopup extends StatefulWidget {
  final List<String> trainingDates;
  final int initialYear;

  const CalendarPopup({
    Key? key,
    required this.trainingDates,
    required this.initialYear,
  }) : super(key: key);

  @override
  _CalendarPopupState createState() => _CalendarPopupState();
}

class _CalendarPopupState extends State<CalendarPopup> {
  late ScrollController _scrollCtrl;
  bool _hasJumped = false;

  @override
  void initState() {
    super.initState();
    _scrollCtrl = ScrollController();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1) Höhe des Sheets (70% des Bildschirms)
    final sheetHeight = MediaQuery.of(context).size.height * 0.7;

    // 2) Jahres-Gitter-Berechnung (wie im Calendar-Widget)
    final firstOfYear = DateTime(widget.initialYear, 1, 1);
    final lastOfYear  = DateTime(widget.initialYear, 12, 31);
    final startOffset = (firstOfYear.weekday + 6) % 7; // Mo→0…So→6
    final gridStart   = firstOfYear.subtract(Duration(days: startOffset));
    final endOffset   = 6 - ((lastOfYear.weekday + 6) % 7);
    final gridEnd     = lastOfYear.add(Duration(days: endOffset));
    final totalDays   = gridEnd.difference(gridStart).inDays + 1;
    final weekCount   = (totalDays / 7).ceil();

    // 3) Box-Größe und Rand wie im Calendar-Popup
    const boxSize   = 24.0;
    const boxMargin = 2.0;
    final cellWidth = boxSize + boxMargin * 2;

    // 4) Berechne, in welcher Woche wir heute sind (wenn es das aktuelle Jahr ist)
    int targetWeek = 0;
    final today = DateTime.now();
    if (today.year == widget.initialYear) {
      final diff = today.difference(gridStart).inDays;
      targetWeek = (diff / 7).floor().clamp(0, weekCount - 1);
    }

    // 5) Viewport-Breite (abzüglich Padding)
    final viewportWidth = MediaQuery.of(context).size.width - 16 * 2;

    // 6) Gewünschter Scroll-Offset, so dass die aktuelle Woche mittig steht
    final desiredOffset = targetWeek * cellWidth - (viewportWidth - boxSize) / 2;

    // 7) Nach dem ersten Frame zum Offset springen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasJumped && _scrollCtrl.hasClients) {
        final max = _scrollCtrl.position.maxScrollExtent;
        _scrollCtrl.jumpTo(desiredOffset.clamp(0.0, max));
        _hasJumped = true;
      }
    });

    // 8) Gesamtbreite des Kalenders
    final calendarWidth = weekCount * cellWidth;

    return SizedBox(
      height: sheetHeight,
      child: Material(
        color: Theme.of(context).scaffoldBackgroundColor,
        shape:
            const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            controller: _scrollCtrl,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: calendarWidth,
              child: Calendar(
                trainingDates: widget.trainingDates,
                year: widget.initialYear,
                showNavigation: false,
                onDayTap: (date) {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushNamed(
                    '/training_details',
                    arguments: date,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

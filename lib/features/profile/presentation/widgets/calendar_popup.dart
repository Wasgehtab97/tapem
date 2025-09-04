// lib/features/profile/presentation/widgets/calendar_popup.dart

import 'package:flutter/material.dart';
import 'package:tapem/app_router.dart'; // ← HIER DEN IMPORT HINZUFÜGEN
import 'calendar.dart';

/// Modal Bottom Sheet mit größerem, horizontal scrollbarem Jahres-Heatmap-Kalender.
/// Öffnet automatisch in der aktuellen Kalenderwoche; beim Tippen auf ein Datum
/// schließt es sich und navigiert zu AppRouter.trainingDetails.
class CalendarPopup extends StatefulWidget {
  final List<String> trainingDates;
  final int initialYear;
  final String userId;
  final bool navigateOnTap;

  const CalendarPopup({
    Key? key,
    required this.trainingDates,
    required this.initialYear,
    required this.userId,
    this.navigateOnTap = true,
  }) : super(key: key);

  @override
  _CalendarPopupState createState() => _CalendarPopupState();
}

class _CalendarPopupState extends State<CalendarPopup> {
  late final ScrollController _scrollCtrl;
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
    final sheetHeight = MediaQuery.of(context).size.height * 0.6;
    final firstOfYear = DateTime(widget.initialYear, 1, 1);
    final lastOfYear = DateTime(widget.initialYear, 12, 31);
    final startOffset = (firstOfYear.weekday + 6) % 7;
    final gridStart = firstOfYear.subtract(Duration(days: startOffset));
    final totalDays = lastOfYear.difference(gridStart).inDays + 1;
    final weekCount = (totalDays / 7).ceil();

    const boxSize = 24.0;
    const boxMargin = 2.0;
    final cellWidth = boxSize + boxMargin * 2;

    final today = DateTime.now();
    int targetWeek = 0;
    if (today.year == widget.initialYear) {
      final diff = today.difference(gridStart).inDays;
      targetWeek = (diff / 7).floor().clamp(0, weekCount - 1);
    }

    final viewportWidth = MediaQuery.of(context).size.width - 32;
    final desiredOffset =
        targetWeek * cellWidth - (viewportWidth - boxSize) / 2;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasJumped && _scrollCtrl.hasClients) {
        final max = _scrollCtrl.position.maxScrollExtent;
        _scrollCtrl.jumpTo(desiredOffset.clamp(0.0, max));
        _hasJumped = true;
      }
    });

    return SizedBox(
      height: sheetHeight,
      child: Material(
        color: Theme.of(context).scaffoldBackgroundColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            controller: _scrollCtrl,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: weekCount * cellWidth,
              child: Calendar(
                trainingDates: widget.trainingDates,
                year: widget.initialYear,
                showNavigation: false,
                onDayTap: (date) {
                  Navigator.of(context).pop(date);
                  if (widget.navigateOnTap) {
                    Navigator.of(context).pushNamed(
                      AppRouter.trainingDetails,
                      arguments: {'userId': widget.userId, 'date': date},
                    );
                  }
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

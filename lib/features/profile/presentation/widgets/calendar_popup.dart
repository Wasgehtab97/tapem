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
  final Map<String, String>? gymIdsByDate;

  const CalendarPopup({
    Key? key,
    required this.trainingDates,
    required this.initialYear,
    required this.userId,
    this.navigateOnTap = true,
    this.gymIdsByDate,
  }) : super(key: key);

  @override
  _CalendarPopupState createState() => _CalendarPopupState();
}

class _CalendarPopupState extends State<CalendarPopup> {
  late final ScrollController _scrollCtrl;
  static const int _firstSupportedYear = 2025;
  late int _activeYear;
  bool _hasScheduledInitialJump = false;

  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _scrollCtrl = ScrollController();
    _activeYear = widget.initialYear < _firstSupportedYear
        ? _firstSupportedYear
        : widget.initialYear;
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  _YearMetrics _calculateMetrics(int year) {
    final firstOfYear = DateTime(year, 1, 1);
    final lastOfYear = DateTime(year, 12, 31);
    final startOffset = (firstOfYear.weekday + 6) % 7;
    final gridStart = firstOfYear.subtract(Duration(days: startOffset));
    final endOffset = 6 - ((lastOfYear.weekday + 6) % 7);
    final gridEnd = lastOfYear.add(Duration(days: endOffset));
    final totalDays = gridEnd.difference(gridStart).inDays + 1;
    final weekCount = (totalDays / 7).ceil();
    return _YearMetrics(gridStart: gridStart, weekCount: weekCount);
  }

  void _scheduleJumpToRelevantWeek({bool animate = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) {
        return;
      }

      const boxSize = 24.0;
      const boxMargin = 2.0;
      final metrics = _calculateMetrics(_activeYear);
      final cellWidth = boxSize + boxMargin * 2;
      final viewportWidth = MediaQuery.of(context).size.width - 32;
      final today = DateTime.now();
      int targetWeek = 0;
      if (today.year == _activeYear) {
        final diff = today.difference(metrics.gridStart).inDays;
        targetWeek = (diff / 7).floor().clamp(0, metrics.weekCount - 1);
      }
      final desiredOffset =
          targetWeek * cellWidth - (viewportWidth - boxSize) / 2;
      final max = _scrollCtrl.position.maxScrollExtent;
      final target = desiredOffset.clamp(0.0, max);
      if (animate && _scrollCtrl.position.haveDimensions) {
        _scrollCtrl.animateTo(
          target,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      } else {
        _scrollCtrl.jumpTo(target);
      }
    });
  }

  void _handleYearChanged(int year) {
    if (year == _activeYear) {
      return;
    }
    setState(() {
      _activeYear = year;
    });
    _scheduleJumpToRelevantWeek(animate: true);
  }

  @override
  Widget build(BuildContext context) {
    final sheetHeight = MediaQuery.of(context).size.height * 0.6;
    const boxSize = 24.0;
    const boxMargin = 2.0;
    final cellWidth = boxSize + boxMargin * 2;
    final metrics = _calculateMetrics(_activeYear);

    if (!_hasScheduledInitialJump) {
      _hasScheduledInitialJump = true;
      _scheduleJumpToRelevantWeek();
    }

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
              width: metrics.weekCount * cellWidth,
              child: Calendar(
                trainingDates: widget.trainingDates,
                year: _activeYear,
                minYear: _firstSupportedYear,
                onYearChanged: _handleYearChanged,
                showDayNumbers: true,
                onDayTap: (date) {
                  Navigator.of(context).pop(date);
                  if (widget.navigateOnTap) {
                    final args = <String, dynamic>{
                      'userId': widget.userId,
                      'date': date,
                    };
                    final gymId = widget.gymIdsByDate?[_formatDateKey(date)];
                    if (gymId != null) {
                      args['gymId'] = gymId;
                    }
                    Navigator.of(context).pushNamed(
                      AppRouter.trainingDetails,
                      arguments: args,
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

class _YearMetrics {
  const _YearMetrics({required this.gridStart, required this.weekCount});

  final DateTime gridStart;
  final int weekCount;
}

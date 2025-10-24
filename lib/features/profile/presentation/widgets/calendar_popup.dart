// lib/features/profile/presentation/widgets/calendar_popup.dart

import 'dart:math' as math;

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
  late int _currentYear;
  int? _lastJumpedYear;

  static const int _minYear = 2025;

  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _scrollCtrl = ScrollController();
    _currentYear = math.max(_minYear, widget.initialYear);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _setYear(int year) {
    if (year == _currentYear) {
      return;
    }
    setState(() {
      _currentYear = year;
      _lastJumpedYear = null;
    });
  }

  void _prevYear() {
    if (_currentYear > _minYear) {
      _setYear(_currentYear - 1);
    }
  }

  void _nextYear() {
    _setYear(_currentYear + 1);
  }

  @override
  Widget build(BuildContext context) {
    final sheetHeight = MediaQuery.of(context).size.height * 0.6;
    final firstOfYear = DateTime(_currentYear, 1, 1);
    final lastOfYear = DateTime(_currentYear, 12, 31);
    final startOffset = (firstOfYear.weekday + 6) % 7;
    final gridStart = firstOfYear.subtract(Duration(days: startOffset));
    final totalDays = lastOfYear.difference(gridStart).inDays + 1;
    final weekCount = (totalDays / 7).ceil();

    const boxSize = 24.0;
    const boxMargin = 2.0;
    final cellWidth = boxSize + boxMargin * 2;

    final today = DateTime.now();
    int targetWeek = 0;
    if (today.year == _currentYear) {
      final diff = today.difference(gridStart).inDays;
      targetWeek = (diff / 7).floor().clamp(0, weekCount - 1);
    }

    final viewportWidth = MediaQuery.of(context).size.width - 32;
    final desiredOffset =
        targetWeek * cellWidth - (viewportWidth - boxSize) / 2;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_lastJumpedYear != _currentYear && _scrollCtrl.hasClients) {
        final max = _scrollCtrl.position.maxScrollExtent;
        final targetOffset =
            today.year == _currentYear ? desiredOffset : 0.0;
        _scrollCtrl.jumpTo(targetOffset.clamp(0.0, max));
        _lastJumpedYear = _currentYear;
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
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _currentYear > _minYear ? _prevYear : null,
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        '$_currentYear',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _nextYear,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollCtrl,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: weekCount * cellWidth,
                    child: Calendar(
                      trainingDates: widget.trainingDates,
                      year: _currentYear,
                      showNavigation: false,
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
            ],
          ),
        ),
      ),
    );
  }
}

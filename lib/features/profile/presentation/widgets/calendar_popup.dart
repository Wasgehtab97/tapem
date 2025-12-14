// lib/features/profile/presentation/widgets/calendar_popup.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/theme/design_tokens.dart';
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
  final List<String> scheduledDates;
  final Map<String, Color> scheduledColorsByDate;

  const CalendarPopup({
    Key? key,
    required this.trainingDates,
    required this.initialYear,
    required this.userId,
    this.navigateOnTap = true,
    this.gymIdsByDate,
    this.scheduledDates = const [],
    this.scheduledColorsByDate = const {},
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
    const boxSize = 24.0;
    const boxMargin = 2.0;
    final cellWidth = boxSize + boxMargin * 2;
    final metrics = _calculateMetrics(_activeYear);

    if (!_hasScheduledInitialJump) {
      _hasScheduledInitialJump = true;
      _scheduleJumpToRelevantWeek();
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1E1E1E).withOpacity(0.85),
              const Color(0xFF121212).withOpacity(0.90),
            ],
          ),
          borderRadius: BorderRadius.circular(AppRadius.cardLg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.cardLg),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppRadius.cardLg),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Trainingstage',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Absolviert',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.white70),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(2),
                                border: Border.all(
                                  color: Colors.white70,
                                  width: 1,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Geplanter Plan',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.white70),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      height: 300, // Fixed height for the calendar area
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
                            scheduledDates: widget.scheduledDates,
                            scheduledColorsByDate:
                                widget.scheduledColorsByDate,
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

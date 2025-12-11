// lib/features/profile/presentation/widgets/calendar.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';

/// GitHub-Style Jahres-Heatmap.
/// Klick‐Callback nur innerhalb des Popups aktiv.
class Calendar extends StatefulWidget {
  final List<String> trainingDates;
  final void Function(DateTime)? onDayTap;
  final bool showNavigation;
  final int year;
  final bool showDayNumbers;
  final int? minYear;
  final int? maxYear;
  final ValueChanged<int>? onYearChanged;

  Calendar({
    Key? key,
    required this.trainingDates,
    this.onDayTap,
    this.showNavigation = true,
    this.showDayNumbers = false,
    int? year,
    this.minYear,
    this.maxYear,
    this.onYearChanged,
  }) : year = year ?? DateTime.now().year,
       super(key: key);

  @override
  State<Calendar> createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  late int _year;

  @override
  void initState() {
    super.initState();
    _year = _normalizeYear(widget.year);
  }

  @override
  void didUpdateWidget(covariant Calendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final normalizedYear = _normalizeYear(widget.year);
    if (normalizedYear != _year) {
      setState(() {
        _year = normalizedYear;
      });
    }
  }

  int get _minYear => widget.minYear ?? -0x7fffffff;
  int get _maxYear => widget.maxYear ?? 0x7fffffff;

  bool get _canGoPrev => _year > _minYear;
  bool get _canGoNext => _year < _maxYear;

  int _normalizeYear(int year) {
    if (year < _minYear) {
      return _minYear;
    }
    if (year > _maxYear) {
      return _maxYear;
    }
    return year;
  }

  void _prevYear() {
    if (!_canGoPrev) return;
    setState(() {
      _year--;
    });
    widget.onYearChanged?.call(_year);
  }

  void _nextYear() {
    if (!_canGoNext) return;
    setState(() {
      _year++;
    });
    widget.onYearChanged?.call(_year);
  }

  bool _isNeutralScheme(ColorScheme scheme) {
    return scheme.primary.value == Colors.white.value &&
        scheme.secondary.value == Colors.white.value;
  }

  Color _resolveTrainingFillColor(
    ThemeData theme,
    AppBrandTheme? brandTheme,
    bool isNeutralTheme,
  ) {
    final baseColor = brandTheme?.outline ?? theme.colorScheme.secondary;
    final opacity = isNeutralTheme ? 0.7 : 0.95;
    return baseColor.withOpacity(opacity);
  }

  Color _resolveTrainingLabelColor(
    ThemeData theme,
    AppBrandTheme? brandTheme,
    bool isNeutralTheme,
  ) {
    if (brandTheme != null && !isNeutralTheme) {
      return brandTheme.onBrand.withOpacity(0.9);
    }
    return theme.colorScheme.onSecondary.withOpacity(0.9);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final accentColor = brandTheme?.outline ?? theme.colorScheme.secondary;
    final isNeutralTheme = _isNeutralScheme(theme.colorScheme);
    final trainingFillColor =
        _resolveTrainingFillColor(theme, brandTheme, isNeutralTheme);
    final trainingLabelColor =
        _resolveTrainingLabelColor(theme, brandTheme, isNeutralTheme);
    final locale = Localizations.localeOf(context).toString();
    final today = DateTime.now();

    final firstOfYear = DateTime(_year, 1, 1);
    final lastOfYear = DateTime(_year, 12, 31);

    final startOffset = (firstOfYear.weekday + 6) % 7;
    final gridStart = firstOfYear.subtract(Duration(days: startOffset));
    final endOffset = 6 - ((lastOfYear.weekday + 6) % 7);
    final gridEnd = lastOfYear.add(Duration(days: endOffset));
    final totalDays = gridEnd.difference(gridStart).inDays + 1;
    final weekCount = (totalDays / 7).ceil();

    return LayoutBuilder(
      builder: (ctx, constraints) {
        const hPad = 16.0;
        const margin = 1.0;
        final usable = constraints.maxWidth - hPad * 2;
        final rawSize = (usable - weekCount * margin * 2) / weekCount;
        final cellSize = rawSize.clamp(4.0, usable);

        final monthLabelTextStyle =
            theme.textTheme.bodySmall?.copyWith(color: accentColor) ??
            TextStyle(color: accentColor);


        final header =
            widget.showNavigation
                ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: hPad),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left, size: 20),
                        onPressed: _canGoPrev ? _prevYear : null,
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            '$_year',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right, size: 20),
                        onPressed: _canGoNext ? _nextYear : null,
                      ),
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
                      width: cellSize,
                      height: cellSize,
                      margin: const EdgeInsets.all(margin),
                    );
                  }

                  final key = DateFormat('yyyy-MM-dd').format(date);
                  final isTrain = widget.trainingDates.contains(key);
                  final isToday =
                      date.year == today.year &&
                      date.month == today.month &&
                      date.day == today.day;

                  final textStyle = theme.textTheme.labelSmall?.copyWith(
                        fontSize: 8,
                        color: isTrain
                            ? trainingLabelColor
                            : theme.textTheme.labelSmall?.color ??
                                theme.colorScheme.onSurface.withOpacity(0.7),
                      ) ??
                      TextStyle(
                        fontSize: 8,
                        color: isTrain
                            ? trainingLabelColor
                            : theme.colorScheme.onSurface.withOpacity(0.7),
                      );

                  Widget box = Container(
                    width: cellSize,
                    height: cellSize,
                    margin: const EdgeInsets.all(margin),
                    decoration: BoxDecoration(
                      color:
                          isTrain
                              ? trainingFillColor
                              : Colors.transparent,
                      border: Border.all(
                        color:
                            isToday
                                ? theme.colorScheme.error
                                : theme.dividerColor,
                        width: isToday ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: widget.showDayNumbers
                        ? Padding(
                            padding: const EdgeInsets.all(2),
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: Text('${date.day}', style: textStyle),
                            ),
                          )
                        : null,
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

        final monthsRow = Padding(
          padding: const EdgeInsets.symmetric(horizontal: hPad),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(12, (index) {
              final monthDate = DateTime(_year, index + 1, 1);
              final fullLabel = DateFormat.MMM(locale).format(monthDate);
              final shortLabel =
                  fullLabel.length <= 2 ? fullLabel : fullLabel.substring(0, 2);
              return Text(shortLabel, style: monthLabelTextStyle);
            }),
          ),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            header,
            SizedBox(height: 20, child: monthsRow),
            const SizedBox(height: 4),
            grid,
          ],
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/logging/elog.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/features/profile/presentation/widgets/calendar.dart';
import 'package:tapem/features/profile/presentation/widgets/calendar_popup.dart';
import '../../providers/creatine_provider.dart';
import '../../data/creatine_repository.dart';

class CreatineScreen extends StatefulWidget {
  final String? userId;
  const CreatineScreen({super.key, this.userId});

  @override
  State<CreatineScreen> createState() => _CreatineScreenState();
}

class _CreatineScreenState extends State<CreatineScreen> {
  String _uid = '';

  Future<void> _openCalendar(CreatineProvider prov) async {
    elogUi('creatine_open_popup', {});
    final selected = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CalendarPopup(
        trainingDates: prov.intakeDates.toList(),
        initialYear: DateTime.now().year,
        userId: _uid,
        navigateOnTap: false,
      ),
    );
    if (selected != null) {
      prov.setSelectedDate(selected);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loc = AppLocalizations.of(context)!;
      try {
        _uid = (widget.userId?.trim().isNotEmpty == true)
            ? widget.userId!.trim()
            : currentUidOrFail();
        context
            .read<CreatineProvider>()
            .loadIntakeDates(_uid, DateTime.now().year);
        elogUi('creatine_open_screen', {});
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${loc.errorPrefix}: $e')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<CreatineProvider>();
    final loc = AppLocalizations.of(context)!;
    final year = DateTime.now().year;
    final selected = prov.selectedDate;
    final dateKey = prov.selectedDateKey;
    final isTaken = prov.intakeDates.contains(dateKey);
    final formatted = DateFormat('dd.MM.yyyy').format(selected);
    final isToday = atStartOfLocalDay(selected)
        .isAtSameMomentAs(atStartOfLocalDay(nowLocal()));
    final isYesterday = atStartOfLocalDay(selected)
        .isAtSameMomentAs(atStartOfLocalDay(nowLocal()).subtract(const Duration(days: 1)));
    String label;
    if (isTaken) {
      label = loc.creatineRemoveMarking;
    } else if (isToday) {
      label = loc.creatineTakenToday;
    } else if (isYesterday) {
      label = loc.creatineConfirmForDate(formatted);
    } else {
      label = loc.creatineConfirmForDate(formatted);
    }
    final canToggle = prov.canToggle;
    final buttonEnabled = canToggle && !prov.busy && _uid.isNotEmpty;

    Widget body;
    if (prov.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (prov.error != null) {
      body = Center(child: Text('${loc.errorPrefix}: ${prov.error}'));
    } else {
      body = Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _openCalendar(prov),
                child: Stack(
                  children: [
                    Calendar(
                      trainingDates: prov.intakeDates.toList(),
                      showNavigation: false,
                      year: year,
                    ),
                    _SelectionOverlay(date: selected, year: year),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            GestureDetector(
              onTap: () {
                if (!buttonEnabled && !prov.busy && _uid.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc.creatineOnlyTodayOrYesterday)),
                  );
                }
              },
              child: ElevatedButton.icon(
                onPressed: buttonEnabled
                    ? () async {
                        try {
                          final added = await prov.toggleIntake(_uid);
                          final snack = added
                              ? loc.creatineSaved(formatted)
                              : loc.creatineRemoved(formatted);
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text(snack)));
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${loc.errorPrefix}: $e')),
                          );
                        }
                      }
                    : null,
                icon: const Icon(Icons.check),
                label: Text(label),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(loc.creatineTitle)),
      body: body,
    );
  }
}

class _SelectionOverlay extends StatelessWidget {
  final DateTime date;
  final int year;
  const _SelectionOverlay({required this.date, required this.year});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (ctx, constraints) {
          const hPad = 16.0;
          const margin = 1.0;
          final firstOfYear = DateTime(year, 1, 1);
          final lastOfYear = DateTime(year, 12, 31);
          final startOffset = (firstOfYear.weekday + 6) % 7;
          final gridStart = firstOfYear.subtract(Duration(days: startOffset));
          final endOffset = 6 - ((lastOfYear.weekday + 6) % 7);
          final gridEnd = lastOfYear.add(Duration(days: endOffset));
          final totalDays = gridEnd.difference(gridStart).inDays + 1;
          final weekCount = (totalDays / 7).ceil();

          final usable = constraints.maxWidth - hPad * 2;
          final rawSize = (usable - weekCount * margin * 2) / weekCount;
          final cellSize = rawSize.clamp(4.0, usable);

          final diff = date.difference(gridStart).inDays;
          if (diff < 0 || diff >= totalDays) {
            return const SizedBox.shrink();
          }
          final w = diff ~/ 7;
          final d = diff % 7;
          final left = hPad + w * (cellSize + margin * 2);
          final top = 20 + 4 + d * (cellSize + margin * 2);

          final today = DateTime.now();
          final isToday = today.year == date.year &&
              today.month == date.month &&
              today.day == date.day;
          final color = isToday
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.error;
          final width = isToday ? 3.0 : 2.0;

          return Stack(
            children: [
              Positioned(
                left: left,
                top: top,
                child: Container(
                  width: cellSize,
                  height: cellSize,
                  decoration: BoxDecoration(
                    border: Border.all(color: color, width: width),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

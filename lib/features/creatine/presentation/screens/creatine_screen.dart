import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/logging/elog.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/features/profile/presentation/widgets/calendar.dart';
import '../../providers/creatine_provider.dart';

class CreatineScreen extends StatefulWidget {
  final String? userId;
  const CreatineScreen({super.key, this.userId});

  @override
  State<CreatineScreen> createState() => _CreatineScreenState();
}

class _CreatineScreenState extends State<CreatineScreen> {
  late final String _uid;

  @override
  void initState() {
    super.initState();
    final auth = widget.userId;
    _uid = auth ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<CreatineProvider>()
          .loadIntakeDates(_uid, DateTime.now().year);
      elogUi('creatine_open_screen', {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<CreatineProvider>();
    final loc = AppLocalizations.of(context)!;
    final year = DateTime.now().year;
    final selected = prov.selectedDate;
    final dateKey = CreatineProvider.dateKeyFrom(selected);
    final isTaken = prov.intakeDates.contains(dateKey);
    final today = DateTime.now();
    final isToday = selected.year == today.year &&
        selected.month == today.month &&
        selected.day == today.day;
    final formatted = DateFormat('dd.MM.yyyy').format(selected);
    String label;
    if (isTaken) {
      label = loc.creatineRemoveMarking;
    } else {
      label = isToday
          ? loc.creatineTakenToday
          : loc.creatineConfirmForDate(formatted);
    }

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
              child: Stack(
                children: [
                  Calendar(
                    trainingDates: prov.intakeDates.toList(),
                    showNavigation: false,
                    year: year,
                    onDayTap: (d) => prov.setSelectedDate(d),
                  ),
                  _SelectionOverlay(date: selected, year: year),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  final added = await prov.toggleIntake(_uid, dateKey);
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
              },
              icon: const Icon(Icons.check),
              label: Text(label),
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

          return Positioned(
            left: left,
            top: top,
            child: Container(
              width: cellSize,
              height: cellSize,
              decoration: BoxDecoration(
                border: Border.all(color: color, width: width),
              ),
            ),
          );
        },
      ),
    );
  }
}

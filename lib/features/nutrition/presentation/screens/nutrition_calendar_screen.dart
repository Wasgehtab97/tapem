import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/features/nutrition/providers/nutrition_provider.dart';
import 'package:tapem/features/nutrition/domain/utils/nutrition_dates.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class NutritionCalendarScreen extends ConsumerStatefulWidget {
  const NutritionCalendarScreen({super.key});

  @override
  ConsumerState<NutritionCalendarScreen> createState() =>
      _NutritionCalendarScreenState();
}

class _NutritionCalendarScreenState
    extends ConsumerState<NutritionCalendarScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadYear());
  }

  Future<void> _loadYear() async {
    final auth = ref.read(authControllerProvider);
    final uid = auth.userId;
    if (uid == null || uid.isEmpty) return;
    final year = DateTime.now().year;
    await ref.read(nutritionProvider).loadYear(uid, year);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final state = ref.watch(nutritionProvider);
    final year = DateTime.now().year;
    final summary = state.yearSummary;
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.nutritionCalendarTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Text(
            loc.nutritionCalendarIntro,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          if (state.isLoadingYear)
            const Center(child: CircularProgressIndicator())
          else ...[
            _LegendRow(),
            const SizedBox(height: 12),
            for (var month = 1; month <= 12; month++)
              _MonthCard(
                year: year,
                month: month,
                days: summary?.days ?? const {},
              ),
          ],
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _LegendChip(label: loc.nutritionLegendUnder, color: Colors.redAccent),
        _LegendChip(label: loc.nutritionLegendOn, color: Colors.green),
        _LegendChip(label: loc.nutritionLegendOver, color: Colors.orange),
        Text(loc.nutritionLegendHint, style: theme.textTheme.labelSmall),
      ],
    );
  }
}

class _LegendChip extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: CircleAvatar(backgroundColor: color, radius: 6),
      label: Text(label),
    );
  }
}

class _MonthCard extends StatelessWidget {
  final int year;
  final int month;
  final Map<String, String> days;

  const _MonthCard({
    required this.year,
    required this.month,
    required this.days,
  });

  Color _statusColor(BuildContext context, String? status) {
    switch (status) {
      case 'on':
        return Colors.green;
      case 'over':
        return Colors.orange;
      case 'under':
        return Colors.redAccent;
      default:
        return Theme.of(context).dividerColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final offset = (firstDay.weekday + 6) % 7; // Monday=0
    final totalCells = offset + daysInMonth;
    final monthLabel = DateFormat.MMMM().format(firstDay);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              monthLabel,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: totalCells,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, index) {
                if (index < offset) {
                  return const SizedBox.shrink();
                }
                final day = index - offset + 1;
                final key = nutritionDateKeyFromParts(year, month, day);
                final status = days[key];
                return Container(
                  decoration: BoxDecoration(
                    color: _statusColor(context, status),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$day',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

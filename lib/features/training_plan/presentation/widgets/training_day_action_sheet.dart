import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TrainingDayActionSheet extends StatelessWidget {
  const TrainingDayActionSheet({
    super.key,
    required this.date,
    this.assignedPlanName,
    required this.onOpenDetails,
    required this.onOpenPlanSelection,
  });

  final DateTime date;
  final String? assignedPlanName;
  final VoidCallback onOpenDetails;
  final VoidCallback onOpenPlanSelection;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedDate =
        DateFormat('EEEE, dd.MM.yyyy', Localizations.localeOf(context).toString())
            .format(date);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              formattedDate,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (assignedPlanName != null && assignedPlanName!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Aktueller Plan: $assignedPlanName',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.calendar_today_outlined),
              title: const Text('Trainingdetailspage'),
              onTap: () {
                Navigator.pop(context);
                onOpenDetails();
              },
            ),
            ListTile(
              leading: const Icon(Icons.view_list_rounded),
              title: const Text('Plan'),
              onTap: () {
                Navigator.pop(context);
                onOpenPlanSelection();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}


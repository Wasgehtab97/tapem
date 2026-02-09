import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/widgets/brand_modal.dart';

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
    final brand = theme.extension<AppBrandTheme>();
    final accent = brand?.outline ?? theme.colorScheme.secondary;
    final formattedDate = DateFormat(
      'EEEE, dd.MM.yyyy',
      Localizations.localeOf(context).toString(),
    ).format(date);
    final titleDate = toBeginningOfSentenceCase(formattedDate);
    final planSubtitle =
        assignedPlanName != null && assignedPlanName!.isNotEmpty
        ? 'Aktueller Plan: $assignedPlanName'
        : 'Plan für diesen Tag auswählen';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: BrandModalSurface(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BrandModalHeader(
              icon: Icons.calendar_today_rounded,
              accent: accent,
              title: titleDate,
              subtitle: 'Aktion für diesen Trainingstag',
              onClose: () => Navigator.pop(context),
            ),
            const SizedBox(height: 16),
            BrandModalOptionCard(
              title: 'Trainingdetailspage',
              subtitle: 'Sätze und Verlauf für den Tag öffnen',
              icon: Icons.calendar_today_outlined,
              accent: accent,
              onTap: () {
                Navigator.pop(context);
                onOpenDetails();
              },
            ),
            const SizedBox(height: 10),
            BrandModalOptionCard(
              title: 'Plan',
              subtitle: planSubtitle,
              icon: Icons.view_list_rounded,
              accent: accent,
              onTap: () {
                Navigator.pop(context);
                onOpenPlanSelection();
              },
            ),
          ],
        ),
      ),
    );
  }
}

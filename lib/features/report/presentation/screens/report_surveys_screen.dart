import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_brand_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/premium_action_card.dart';
import '../../../../core/widgets/premium_leading_icon.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../survey/presentation/screens/survey_overview_screen.dart';
import '../../../survey/presentation/widgets/create_survey_sheet.dart';
import '../../../survey/survey_provider.dart' as survey_riverpod;

class ReportSurveysScreen extends ConsumerWidget {
  final String gymId;

  const ReportSurveysScreen({super.key, required this.gymId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final brandColor =
        theme.extension<AppBrandTheme>()?.outline ?? theme.colorScheme.secondary;

    final surveyState = ref.watch(survey_riverpod.surveyProvider);

    // Sicherstellen, dass wir offene/abgeschlossene Umfragen hören.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(survey_riverpod.surveyProvider).listen(gymId);
    });

    final openCount = surveyState.openSurveys.length;
    final closedCount = surveyState.closedSurveys.length;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(loc.reportSurveysTitle),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: brandColor,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.scaffoldBackgroundColor,
              Color.alphaBlend(
                brandColor.withOpacity(0.05),
                theme.scaffoldBackgroundColor,
              ),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Starte Umfragen und werte das Feedback deiner Mitglieder aus.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: PremiumActionCard(
                    title: loc.reportCreateSurveyTitle,
                    subtitle: '',
                    leading: const PremiumLeadingIcon(
                      icon: Icons.add_circle_outline,
                    ),
                    onTap: () => _showCreateSurveyDialog(context),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: PremiumActionCard(
                    title: loc.reportViewSurveysTitle,
                    subtitle: openCount > 0 || closedCount > 0
                        ? 'Aktiv: $openCount · Abgeschlossen: $closedCount'
                        : loc.reportSurveysButtonSubtitle,
                    leading: const PremiumLeadingIcon(
                      icon: Icons.poll,
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              SurveyOverviewScreen(gymId: gymId),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCreateSurveyDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => CreateSurveySheet(gymId: gymId),
    );
  }
}

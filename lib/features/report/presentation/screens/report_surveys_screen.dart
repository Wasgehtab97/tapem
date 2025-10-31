import 'package:flutter/material.dart';

import '../../../../core/theme/app_brand_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/brand_action_tile.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../survey/presentation/screens/survey_overview_screen.dart';
import '../../../survey/presentation/widgets/create_survey_sheet.dart';

class ReportSurveysScreen extends StatelessWidget {
  final String gymId;

  const ReportSurveysScreen({super.key, required this.gymId});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final brandColor =
        theme.extension<AppBrandTheme>()?.outline ?? theme.colorScheme.secondary;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.reportSurveysTitle),
        centerTitle: true,
        foregroundColor: brandColor,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              BrandActionTile(
                leadingIcon: Icons.add_circle_outline,
                title: loc.reportCreateSurveyTitle,
                onTap: () => _showCreateSurveyDialog(context),
                variant: BrandActionTileVariant.gradient,
                uiLogEvent: 'REPORT_CARD_RENDER',
              ),
              const SizedBox(height: AppSpacing.sm),
              BrandActionTile(
                leadingIcon: Icons.poll,
                title: loc.reportViewSurveysTitle,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SurveyOverviewScreen(gymId: gymId),
                    ),
                  );
                },
                variant: BrandActionTileVariant.gradient,
                uiLogEvent: 'REPORT_CARD_RENDER',
              ),
            ],
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

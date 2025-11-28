import 'package:flutter/material.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/widgets/brand_gradient_card.dart';
import 'package:tapem/l10n/app_localizations.dart';

import 'report_feedback_screen.dart';
import 'report_members_screen.dart';
import 'report_surveys_screen.dart';
import 'report_usage_screen.dart';

class ReportScreenNew extends StatelessWidget {
  final String gymId;

  const ReportScreenNew({Key? key, required this.gymId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final brandColor =
        theme.extension<AppBrandTheme>()?.outline ?? theme.colorScheme.secondary;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(loc.reportTitle),
        centerTitle: true,
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
                brandColor.withOpacity(0.06),
                theme.scaffoldBackgroundColor,
              ),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: AppSpacing.sm),
                Text(
                  loc.reportTitle,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: brandColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: [
                    _ReportNavigationCard(
                      icon: Icons.groups_rounded,
                      title: loc.reportMembersButtonTitle,
                      subtitle: loc.reportMembersButtonSubtitle,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ReportMembersScreen(gymId: gymId),
                          ),
                        );
                      },
                    ),
                    _ReportNavigationCard(
                      icon: Icons.bar_chart_rounded,
                      title: loc.reportUsageButtonTitle,
                      subtitle: loc.reportUsageButtonSubtitle,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ReportUsageScreen(gymId: gymId),
                          ),
                        );
                      },
                    ),
                    _ReportNavigationCard(
                      icon: Icons.feedback_outlined,
                      title: loc.reportFeedbackButtonTitle,
                      subtitle: loc.reportFeedbackButtonSubtitle,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ReportFeedbackScreen(gymId: gymId),
                          ),
                        );
                      },
                    ),
                    _ReportNavigationCard(
                      icon: Icons.poll,
                      title: loc.reportSurveysButtonTitle,
                      subtitle: loc.reportSurveysButtonSubtitle,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ReportSurveysScreen(gymId: gymId),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}

class _ReportNavigationCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ReportNavigationCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 180,
      child: BrandGradientCard(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.lg,
          horizontal: AppSpacing.md,
        ),
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 36),
            const SizedBox(height: AppSpacing.sm),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

// lib/features/report/presentation/screens/report_screen_new.dart

import 'package:flutter/material.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/widgets/premium_action_card.dart';
import 'package:tapem/core/widgets/premium_leading_icon.dart';
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
    final brandTheme = theme.extension<AppBrandTheme>();
    final brandColor = brandTheme?.outline ?? theme.colorScheme.secondary;

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
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: PremiumActionCard(
                        title: loc.reportMembersButtonTitle,
                        subtitle: loc.reportMembersButtonSubtitle,
                        leading: const PremiumLeadingIcon(icon: Icons.groups_rounded),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ReportMembersScreen(gymId: gymId),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: PremiumActionCard(
                        title: loc.reportUsageButtonTitle,
                        subtitle: loc.reportUsageButtonSubtitle,
                        leading: const PremiumLeadingIcon(icon: Icons.bar_chart_rounded),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ReportUsageScreen(gymId: gymId),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: PremiumActionCard(
                        title: loc.reportFeedbackButtonTitle,
                        subtitle: loc.reportFeedbackButtonSubtitle,
                        leading: const PremiumLeadingIcon(icon: Icons.feedback_outlined),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ReportFeedbackScreen(gymId: gymId),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: PremiumActionCard(
                        title: loc.reportSurveysButtonTitle,
                        subtitle: loc.reportSurveysButtonSubtitle,
                        leading: const PremiumLeadingIcon(icon: Icons.poll),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ReportSurveysScreen(gymId: gymId),
                            ),
                          );
                        },
                      ),
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

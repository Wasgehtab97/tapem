import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_brand_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/brand_action_tile.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../feedback/feedback_provider.dart';
import '../../../feedback/presentation/screens/feedback_overview_screen.dart';

class ReportFeedbackScreen extends StatelessWidget {
  final String gymId;

  const ReportFeedbackScreen({super.key, required this.gymId});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final feedbackProvider = context.watch<FeedbackProvider>();
    final theme = Theme.of(context);
    final brandColor =
        theme.extension<AppBrandTheme>()?.outline ?? theme.colorScheme.secondary;

    if (!feedbackProvider.isLoading && feedbackProvider.entries.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<FeedbackProvider>().loadFeedback(gymId);
      });
    }
    final openCount = feedbackProvider.openEntries.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.reportFeedbackTitle),
        centerTitle: true,
        foregroundColor: brandColor,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: BrandActionTile(
            leadingIcon: Icons.feedback_outlined,
            title: loc.reportFeedbackCardTitle,
            subtitle: openCount > 0
                ? loc.reportFeedbackOpenEntries(openCount)
                : loc.reportFeedbackNoOpenEntries,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => FeedbackOverviewScreen(gymId: gymId),
                ),
              );
            },
            variant: BrandActionTileVariant.gradient,
            uiLogEvent: 'REPORT_CARD_RENDER',
          ),
        ),
      ),
    );
  }
}

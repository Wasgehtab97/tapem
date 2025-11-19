import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_brand_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/brand_action_tile.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../feedback/feedback_provider.dart' as feedback_riverpod;
import '../../../feedback/presentation/screens/feedback_overview_screen.dart';

class ReportFeedbackScreen extends ConsumerWidget {
  final String gymId;

  const ReportFeedbackScreen({super.key, required this.gymId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final feedbackState = ref.watch(feedback_riverpod.feedbackProvider);
    final theme = Theme.of(context);
    final brandColor =
        theme.extension<AppBrandTheme>()?.outline ?? theme.colorScheme.secondary;

    if (!feedbackState.isLoading && feedbackState.entries.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(feedback_riverpod.feedbackProvider).loadFeedback(gymId);
      });
    }
    final openCount = feedbackState.openEntries.length;

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

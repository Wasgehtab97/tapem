import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_brand_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/premium_action_tile.dart';
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

    // Feedback-Daten werden auf der Übersicht bei Bedarf geladen. Hier
    // vermeiden wir erneute Ladevorgänge, um Flackern zu verhindern.
    final openCount = feedbackState.openEntries.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.reportFeedbackTitle),
        centerTitle: true,
        elevation: 0,
        foregroundColor: brandColor,
      ),
      body: Container(
        color: theme.scaffoldBackgroundColor,
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
                  'Verwalte Vorschläge, Beschwerden und Lob deiner Mitglieder.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: PremiumActionTile(
                    leading: const Icon(Icons.feedback_outlined),
                    title: loc.reportFeedbackCardTitle,
                    subtitle: openCount > 0
                        ? loc.reportFeedbackOpenEntries(openCount)
                        : loc.reportFeedbackNoOpenEntries,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              FeedbackOverviewScreen(gymId: gymId),
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
}

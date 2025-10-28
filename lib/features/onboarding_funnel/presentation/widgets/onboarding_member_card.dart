import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../domain/models/onboarding_member_summary.dart';
import '../../../../core/widgets/brand_outline.dart';

class OnboardingMemberCard extends StatelessWidget {
  final OnboardingMemberSummary summary;
  final VoidCallback? onTap;

  const OnboardingMemberCard({super.key, required this.summary, this.onTap});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final dateFormatter = DateFormat.yMMMMd(loc.localeName);

    String _formatDate(DateTime? value) {
      if (value == null) return loc.onboardingDateUnknown;
      return dateFormatter.format(value);
    }

    return BrandOutline(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.sm),
      semanticLabel: loc.onboardingMemberCardTitle(summary.memberNumber),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.onboardingMemberCardTitle(summary.memberNumber),
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            summary.displayName?.isNotEmpty == true
                ? summary.displayName!
                : loc.genericUser,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (summary.email != null && summary.email!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              summary.email!,
              style: theme.textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          _buildDetailRow(
            context,
            label: loc.onboardingMemberRegisteredLabel,
            value: _formatDate(summary.registeredAt),
          ),
          const SizedBox(height: AppSpacing.xs),
          _buildDetailRow(
            context,
            label: loc.onboardingMemberAssignedLabel,
            value: _formatDate(summary.onboardingAssignedAt),
          ),
          const SizedBox(height: AppSpacing.xs),
          _buildDetailRow(
            context,
            label: loc.onboardingMemberTrainingDaysLabel,
            value: loc.onboardingTrainingDays(summary.trainingDays),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

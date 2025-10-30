import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/models/gym_member_detail.dart';
import '../../../../l10n/app_localizations.dart';

class OnboardingMemberCard extends StatelessWidget {
  const OnboardingMemberCard({super.key, required this.detail});

  final GymMemberDetail detail;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context).textTheme;
    final registeredAt = detail.registeredAt ?? detail.userCreatedAt;
    final registrationText = registeredAt != null
        ? DateFormat.yMMMMd(loc.localeName).format(registeredAt)
        : loc.onboardingFunnelRegistrationUnknown;
    final firstScanText = detail.hasCompletedFirstScan
        ? loc.onboardingFunnelFirstScanComplete
        : loc.onboardingFunnelFirstScanPending;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.onboardingFunnelMemberNumberLabel(detail.memberNumber),
              style: theme.titleLarge,
            ),
            if (detail.displayName != null) ...[
              const SizedBox(height: 4),
              Text(
                detail.displayName!,
                style: theme.bodyMedium,
              ),
            ],
            if (detail.email != null && detail.email != detail.displayName) ...[
              const SizedBox(height: 4),
              Text(
                detail.email!,
                style: theme.bodySmall,
              ),
            ],
            const SizedBox(height: 16),
            _InfoRow(
              icon: Icons.calendar_today_outlined,
              label: loc.onboardingFunnelRegistrationLabel,
              value: registrationText,
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.flag_outlined,
              label: loc.onboardingFunnelFirstScanLabel,
              value: firstScanText,
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.fitness_center_outlined,
              label: loc.onboardingFunnelTrainingDaysLabel,
              value: loc.onboardingFunnelTrainingDays(detail.totalTrainingDays),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.labelMedium),
              Text(value, style: theme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

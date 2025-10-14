import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:tapem/l10n/app_localizations.dart';

import '../../domain/session_story_data.dart';

class SessionStoryCard extends StatelessWidget {
  final SessionStoryData data;
  final GlobalKey repaintKey;

  const SessionStoryCard({
    super.key,
    required this.data,
    required this.repaintKey,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final localeName = Localizations.localeOf(context).toString();
    final loc = AppLocalizations.of(context)!;
    final dateFormat = DateFormat.yMMMMd(localeName);
    final headline = '${dateFormat.format(data.occurredAt)} • ${data.gymName ?? data.gymId}';
    final xpLabel = NumberFormat.decimalPattern(localeName).format(data.xpTotal.round());
    final xpTotalText = loc.storycardDailyXp(xpLabel);
    final xpDescription = loc.storycardDailyXpDescription;

    return RepaintBoundary(
      key: repaintKey,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primaryContainer.withOpacity(0.85),
              colorScheme.surfaceTint.withOpacity(0.75),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.all(24),
        child: DefaultTextStyle(
          style: theme.textTheme.bodyMedium!
              .copyWith(color: colorScheme.onPrimaryContainer),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Headline(title: headline),
              const SizedBox(height: 16),
              _XpSummary(
                xpLabel: xpTotalText,
                description: xpDescription,
              ),
              const SizedBox(height: 20),
              _SessionStats(data: data),
              const SizedBox(height: 20),
              if (data.hasPrs) ...[
                Text(
                  loc.storycardPrSectionTitle,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: colorScheme.onPrimaryContainer),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final badge in data.badges)
                      _PrBadgeChip(badge: badge),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Headline extends StatelessWidget {
  final String title;

  const _Headline({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.auto_awesome, color: colorScheme.onPrimaryContainer),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _XpSummary extends StatelessWidget {
  final String xpLabel;
  final String description;

  const _XpSummary({
    required this.xpLabel,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                xpLabel,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onPrimaryContainer.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SessionStats extends StatelessWidget {
  final SessionStoryData data;

  const _SessionStats({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final localeName = Localizations.localeOf(context).toString();
    final loc = AppLocalizations.of(context)!;
    final setsValue = NumberFormat.decimalPattern(localeName).format(data.setCount);
    final durationValueRaw = NumberFormat('#,##0.0', localeName).format(data.durationMinutes);
    final volumeValueRaw = NumberFormat('#,##0.0', localeName).format(data.totalVolume);
    return Row(
      children: [
        _StatTile(
          icon: Icons.fitness_center,
          label: loc.storycardSetsLabel,
          value: setsValue,
          color: colorScheme.primary,
        ),
        const SizedBox(width: 16),
        _StatTile(
          icon: Icons.timer_outlined,
          label: loc.storycardDurationLabel,
          value: loc.storycardDurationValue(durationValueRaw),
          color: colorScheme.secondary,
        ),
        const SizedBox(width: 16),
        _StatTile(
          icon: Icons.monitor_weight,
          label: loc.storycardVolumeLabel,
          value: loc.storycardVolumeValue(volumeValueRaw),
          color: colorScheme.tertiary,
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _PrBadgeChip extends StatelessWidget {
  final SessionStoryBadge badge;

  const _PrBadgeChip({required this.badge});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final loc = AppLocalizations.of(context)!;
    final labelText = _buildLabelText(loc);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.onPrimary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.onPrimaryContainer.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badge.icon, size: 20, color: colorScheme.onPrimaryContainer),
          const SizedBox(width: 8),
          Text(
            labelText,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          if (badge.deltaLabel != null) ...[
            const SizedBox(width: 6),
            Text(
              badge.deltaLabel!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onPrimaryContainer.withOpacity(0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _buildLabelText(AppLocalizations loc) {
    final setWeight = badge.setWeight;
    final setReps = badge.setReps;
    if (setWeight != null && setWeight > 0 && setReps != null && setReps > 0) {
      final unit = badge.unit ?? 'kg';
      final weightLabel = _formatNumber(setWeight);
      final repsValue = setReps;
      final repsLabel = loc.tableHeaderReps;
      return '${badge.label} • $weightLabel $unit × $repsValue $repsLabel';
    }
    return badge.label;
  }

  String _formatNumber(num value) {
    final absValue = value.abs();
    if (absValue >= 100) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }
}

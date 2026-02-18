import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/widgets/premium_action_tile.dart';
import 'package:tapem/l10n/app_localizations.dart';

enum OwnerTaskPriority { high, medium, low }

class OwnerQuickAction {
  const OwnerQuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.uiLogEvent,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String uiLogEvent;
}

class OwnerMetric {
  const OwnerMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.helper,
  });

  final IconData icon;
  final String label;
  final String value;
  final String helper;
}

class OwnerTask {
  const OwnerTask({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.priority = OwnerTaskPriority.medium,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final OwnerTaskPriority priority;
}

class OwnerWorkspaceHeaderSection extends StatelessWidget {
  const OwnerWorkspaceHeaderSection({
    super.key,
    required this.gymId,
    required this.generatedAt,
  });

  final String gymId;
  final DateTime generatedAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final brandColor = brandTheme?.outline ?? theme.colorScheme.secondary;
    final loc = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final timeLabel = DateFormat.yMd(locale).add_Hm().format(generatedAt);

    return Semantics(
      container: true,
      label:
          '${loc.ownerWorkspaceTitle}. '
          '${loc.ownerWorkspaceActiveGym(gymId)}. '
          '${loc.ownerWorkspaceGeneratedAt(timeLabel)}',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.card),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              brandColor.withOpacity(0.18),
              brandColor.withOpacity(0.04),
            ],
          ),
          border: Border.all(color: brandColor.withOpacity(0.26)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.ownerWorkspaceTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              loc.ownerWorkspaceActiveGym(gymId),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.85),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              loc.ownerWorkspaceGeneratedAt(timeLabel),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OwnerMetricsSection extends StatelessWidget {
  const OwnerMetricsSection({super.key, required this.metrics});

  final List<OwnerMetric> metrics;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return _OwnerSection(
      title: loc.ownerSectionKpiTitle,
      subtitle: loc.ownerSectionKpiSubtitle,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const spacing = AppSpacing.xs;
          final width = constraints.maxWidth;
          final columns = width >= 560 ? 5 : (width >= 420 ? 3 : 2);
          final tileWidth = (width - (spacing * (columns - 1))) / columns;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              for (final metric in metrics)
                SizedBox(
                  width: tileWidth,
                  child: _OwnerMetricCard(
                    icon: metric.icon,
                    label: metric.label,
                    value: metric.value,
                    helper: metric.helper,
                    compact: true,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class OwnerTaskSection extends StatelessWidget {
  const OwnerTaskSection({super.key, required this.tasks});

  final List<OwnerTask> tasks;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return _OwnerSection(
      title: loc.ownerSectionTasksTitle,
      subtitle: loc.ownerSectionTasksSubtitle,
      child: tasks.isEmpty
          ? _OwnerNeutralState(
              icon: Icons.check_circle_outline,
              text: loc.ownerTasksNone,
            )
          : Column(
              children: [
                for (final task in tasks)
                  _OwnerTaskTile(
                    icon: task.icon,
                    title: task.title,
                    subtitle: task.subtitle,
                    priority: task.priority,
                    onTap: task.onTap,
                  ),
              ],
            ),
    );
  }
}

class OwnerQuickActionsSection extends StatelessWidget {
  const OwnerQuickActionsSection({super.key, required this.actions});

  final List<OwnerQuickAction> actions;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return _OwnerSection(
      title: loc.ownerSectionQuickActionsTitle,
      subtitle: loc.ownerSectionQuickActionsSubtitle,
      child: Column(
        children: [
          for (final action in actions)
            Semantics(
              button: true,
              label: action.title,
              hint: action.subtitle,
              child: PremiumActionTile(
                key: ValueKey('owner-quick-action-${action.uiLogEvent}'),
                leading: Icon(action.icon),
                title: action.title,
                subtitle: action.subtitle,
                onTap: action.onTap,
              ),
            ),
        ],
      ),
    );
  }
}

class OwnerStateSection extends StatelessWidget {
  const OwnerStateSection({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.ctaLabel,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? ctaLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final brandColor = brandTheme?.outline ?? theme.colorScheme.secondary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: brandColor.withOpacity(0.24)),
              color: theme.colorScheme.surface,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 48, color: brandColor),
                const SizedBox(height: AppSpacing.md),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.72),
                  ),
                ),
                if (ctaLabel != null && onTap != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  ElevatedButton(onPressed: onTap, child: Text(ctaLabel!)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OwnerSection extends StatelessWidget {
  const _OwnerSection({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.68),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        child,
      ],
    );
  }
}

class _OwnerMetricCard extends StatelessWidget {
  const _OwnerMetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.helper,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final String helper;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final brandColor = brandTheme?.outline ?? theme.colorScheme.secondary;

    return Semantics(
      container: true,
      label: '$label: $value',
      hint: helper,
      child: Container(
        constraints: compact
            ? const BoxConstraints(minHeight: 86)
            : const BoxConstraints(minWidth: 158, maxWidth: 240),
        padding: EdgeInsets.all(compact ? AppSpacing.xs : AppSpacing.sm),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: theme.colorScheme.onSurface.withOpacity(0.12),
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              brandColor.withOpacity(0.11),
              brandColor.withOpacity(0.03),
            ],
          ),
        ),
        child: compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 16, color: brandColor),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          value,
                          textAlign: TextAlign.right,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.75),
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 18, color: brandColor),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.65),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    helper,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.72),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _OwnerTaskTile extends StatelessWidget {
  const _OwnerTaskTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.priority,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final OwnerTaskPriority priority;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final color = switch (priority) {
      OwnerTaskPriority.high => theme.colorScheme.error,
      OwnerTaskPriority.medium => theme.colorScheme.secondary,
      OwnerTaskPriority.low => theme.colorScheme.primary,
    };
    final chipLabel = switch (priority) {
      OwnerTaskPriority.high => loc.ownerPriorityHigh,
      OwnerTaskPriority.medium => loc.ownerPriorityMedium,
      OwnerTaskPriority.low => loc.ownerPriorityLow,
    };

    return Semantics(
      button: true,
      label: title,
      hint: '$subtitle ($chipLabel)',
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: color.withOpacity(0.28)),
          color: theme.colorScheme.surface,
        ),
        child: ListTile(
          onTap: onTap,
          leading: Icon(icon, color: color),
          title: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(subtitle),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              chipLabel,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OwnerNeutralState extends StatelessWidget {
  const _OwnerNeutralState({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final brandColor = brandTheme?.outline ?? theme.colorScheme.secondary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: brandColor.withOpacity(0.24)),
      ),
      child: Row(
        children: [
          Icon(icon, color: brandColor),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/widgets/brand_interactive_card.dart';
import 'package:tapem/core/widgets/premium_action_tile.dart';

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

class OwnerQuickActionsSection extends StatelessWidget {
  const OwnerQuickActionsSection({super.key, required this.actions});

  final List<OwnerQuickAction> actions;

  @override
  Widget build(BuildContext context) {
    return _OwnerSection(
      title: 'Schnellzugriff',
      subtitle: 'Alle owner-relevanten Bereiche zentral an einem Ort.',
      child: Column(
        children: [
          for (final action in actions)
            PremiumActionTile(
              leading: Icon(action.icon),
              title: action.title,
              subtitle: action.subtitle,
              onTap: action.onTap,
            ),
        ],
      ),
    );
  }
}

class OwnerInsight {
  const OwnerInsight({
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

class OwnerInsightsSection extends StatelessWidget {
  const OwnerInsightsSection({
    super.key,
    required this.insights,
    this.showBetaHint = false,
  });

  final List<OwnerInsight> insights;
  final bool showBetaHint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final brandColor = brandTheme?.outline ?? theme.colorScheme.secondary;

    return _OwnerSection(
      title: 'Owner Insights',
      subtitle: 'Live-Kontext fuer schnellere Entscheidungen im Studio-Alltag.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final insight in insights)
                _OwnerInsightCard(
                  icon: insight.icon,
                  label: insight.label,
                  value: insight.value,
                  helper: insight.helper,
                ),
            ],
          ),
          if (showBetaHint) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Owner Hub v2 ist aktiv: erweiterte Controls werden schrittweise freigeschaltet.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: brandColor.withOpacity(0.9),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class OwnerDangerZoneSection extends StatelessWidget {
  const OwnerDangerZoneSection({super.key, required this.onReloadClaimsTap});

  final VoidCallback onReloadClaimsTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _OwnerSection(
      title: 'Danger Zone',
      subtitle: 'Nur fuer Sonderfaelle. Diese Aktion wirkt auf Rollen-Claims.',
      child: BrandInteractiveCard(
        semanticLabel: 'Berechtigungen neu laden',
        uiLogEvent: 'OWNER_DANGER_RELOAD_CLAIMS_CARD',
        onTap: onReloadClaimsTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        restingBorderColor: theme.colorScheme.error.withOpacity(0.24),
        activeBorderColor: theme.colorScheme.error.withOpacity(0.48),
        shadowColor: theme.colorScheme.error.withOpacity(0.24),
        child: Row(
          children: [
            Icon(
              Icons.restart_alt_rounded,
              color: theme.colorScheme.error.withOpacity(0.92),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Berechtigungen neu laden',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.error.withOpacity(0.92),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(
              Icons.warning_amber_rounded,
              color: theme.colorScheme.error.withOpacity(0.9),
            ),
          ],
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
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.65),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        child,
      ],
    );
  }
}

class _OwnerInsightCard extends StatelessWidget {
  const _OwnerInsightCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.helper,
  });

  final IconData icon;
  final String label;
  final String value;
  final String helper;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final brandColor = brandTheme?.outline ?? theme.colorScheme.secondary;

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 160, maxWidth: 240),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: theme.colorScheme.onSurface.withOpacity(0.12),
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              brandColor.withOpacity(0.09),
              brandColor.withOpacity(0.02),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: brandColor, size: 18),
              const SizedBox(height: 6),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.64),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                helper,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

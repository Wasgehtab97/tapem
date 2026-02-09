import 'package:flutter/material.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/widgets/brand_modal.dart';
import 'package:tapem/core/widgets/premium_action_tile.dart';
import 'package:tapem/l10n/app_localizations.dart';

class ProfileHubButton extends StatelessWidget {
  const ProfileHubButton({
    super.key,
    required this.onStatsTap,
    required this.onCommunityTap,
    required this.onSurveysTap,
    this.compact = false,
    this.compactTitle,
  });

  final VoidCallback onStatsTap;
  final VoidCallback onCommunityTap;
  final VoidCallback onSurveysTap;
  final bool compact;
  final String? compactTitle;

  void _showHubSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _ProfileHubSheet(
        onStatsTap: onStatsTap,
        onCommunityTap: onCommunityTap,
        onSurveysTap: onSurveysTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final brandColor = brandTheme?.outline ?? theme.colorScheme.secondary;

    return Padding(
      padding: compact
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: PremiumActionTile(
        onTap: () => _showHubSheet(context),
        leading: const Icon(Icons.grid_view_rounded, size: 20),
        title: compact ? (compactTitle ?? 'Entd') : 'Entdecken',
        subtitle: compact ? null : 'Insights & Community',
        accentColor: brandColor,
        margin: EdgeInsets.zero,
        padding: compact
            ? const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 9)
            : null,
      ),
    );
  }
}

class ProfileProgressButton extends StatelessWidget {
  const ProfileProgressButton({
    super.key,
    required this.onTap,
    this.compact = false,
    this.compactTitle,
  });

  final VoidCallback onTap;
  final bool compact;
  final String? compactTitle;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final brandColor = brandTheme?.outline ?? theme.colorScheme.secondary;

    return Padding(
      padding: compact
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: PremiumActionTile(
        onTap: onTap,
        leading: const Icon(Icons.trending_up_rounded, size: 20),
        title: compact ? (compactTitle ?? 'Prog') : loc.progressButtonTitle,
        subtitle: compact ? null : loc.progressButtonSubtitle,
        accentColor: brandColor,
        margin: EdgeInsets.zero,
        padding: compact
            ? const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 9)
            : null,
      ),
    );
  }
}

class ProfileShortcutButton extends StatelessWidget {
  const ProfileShortcutButton({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final brandColor = brandTheme?.outline ?? theme.colorScheme.secondary;

    return Padding(
      padding: compact
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: PremiumActionTile(
        onTap: onTap,
        leading: Icon(icon, size: 20),
        title: title,
        subtitle: compact ? null : subtitle,
        accentColor: brandColor,
        margin: EdgeInsets.zero,
        padding: compact
            ? const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 9)
            : null,
      ),
    );
  }
}

class _ProfileHubSheet extends StatelessWidget {
  const _ProfileHubSheet({
    required this.onStatsTap,
    required this.onCommunityTap,
    required this.onSurveysTap,
  });

  final VoidCallback onStatsTap;
  final VoidCallback onCommunityTap;
  final VoidCallback onSurveysTap;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final brandColor = brandTheme?.outline ?? theme.colorScheme.secondary;

    return BrandModalSheet(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BrandModalHeader(
            icon: Icons.grid_view_rounded,
            accent: brandColor,
            title: 'Entdecken',
            subtitle: 'Insights & Community',
            onClose: () => Navigator.pop(context),
          ),
          const SizedBox(height: 16),
          BrandModalOptionCard(
            title: loc.profileStatsButtonLabel,
            subtitle: loc.profileStatsButtonSubtitle,
            icon: Icons.auto_graph_rounded,
            accent: brandColor,
            onTap: () {
              Navigator.pop(context);
              onStatsTap();
            },
          ),
          const SizedBox(height: 10),
          BrandModalOptionCard(
            title: loc.profileCommunityButtonTitle,
            subtitle: loc.profileCommunityButtonSubtitle,
            icon: Icons.groups_2_rounded,
            accent: brandColor,
            onTap: () {
              Navigator.pop(context);
              onCommunityTap();
            },
          ),
          const SizedBox(height: 10),
          BrandModalOptionCard(
            title: loc.surveyListTitle,
            subtitle: loc.reportViewSurveysTitle,
            icon: Icons.poll_outlined,
            accent: brandColor,
            onTap: () {
              Navigator.pop(context);
              onSurveysTap();
            },
          ),
        ],
      ),
    );
  }
}

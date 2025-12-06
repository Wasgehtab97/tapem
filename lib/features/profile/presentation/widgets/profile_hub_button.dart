import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/widgets/brand_gradient_icon.dart';
import 'package:tapem/l10n/app_localizations.dart';

class ProfileHubButton extends StatelessWidget {
  const ProfileHubButton({
    super.key,
    required this.onStatsTap,
    required this.onCommunityTap,
    required this.onSurveysTap,
  });

  final VoidCallback onStatsTap;
  final VoidCallback onCommunityTap;
  final VoidCallback onSurveysTap;

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
    final loc = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: GestureDetector(
        onTap: () => _showHubSheet(context),
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                brandColor.withOpacity(0.08),
                brandColor.withOpacity(0.02),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24), // Keep same radius or use AppRadius.card
            border: Border.all(
              color: Colors.white.withOpacity(0.05), // Subtle border like other cards
              width: 1,
            ),
             // Removed colorful shadow
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  // Removed circle background for icon to match others or keep it subtle?
                  // The previous buttons had a 56x56 box for icon.
                  // Let's keep the icon simple but brand colored.
                  decoration: BoxDecoration(
                    color: brandColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: BrandGradientIcon(
                    Icons.grid_view_rounded,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Entdecken', // Renamed from "Dashboard"
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'Insights & Community', // Renamed subtitle
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_upward_rounded,
                    color: brandColor,
                    size: 16,
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
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    
    return RepaintBoundary(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withOpacity(0.8),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border(
              top: BorderSide(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 32),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  _HubItem(
                    title: loc.profileStatsButtonLabel,
                    subtitle: loc.profileStatsButtonSubtitle,
                    icon: Icons.auto_graph,
                    onTap: () {
                      Navigator.pop(context);
                      onStatsTap();
                    },
                  ),
                  const SizedBox(height: 16),
                  _HubItem(
                    title: loc.profileCommunityButtonTitle,
                    subtitle: loc.profileCommunityButtonSubtitle,
                    icon: Icons.groups_2,
                    onTap: () {
                      Navigator.pop(context);
                      onCommunityTap();
                    },
                  ),
                  const SizedBox(height: 16),
                  _HubItem(
                    title: loc.surveyListTitle,
                    subtitle: loc.reportViewSurveysTitle,
                    icon: Icons.poll_outlined,
                    onTap: () {
                      Navigator.pop(context);
                      onSurveysTap();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HubItem extends StatelessWidget {
  const _HubItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final brandColor = brandTheme?.outline ?? theme.colorScheme.secondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.05),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: brandColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  icon,
                  color: brandColor,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.iconTheme.color?.withOpacity(0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

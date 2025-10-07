import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/rank_provider.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/features/challenges/presentation/screens/challenge_tab.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/widgets/brand_gradient_text.dart';
import 'package:tapem/core/widgets/brand_interactive_card.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/l10n/app_localizations.dart';

/// Rank landing displayed in the "Rank" tab of the leaderboard.
class RankScreen extends StatefulWidget {
  final String gymId;
  final String deviceId;
  const RankScreen({Key? key, required this.gymId, required this.deviceId})
    : super(key: key);

  @override
  _RankScreenState createState() => _RankScreenState();
}

class _RankScreenState extends State<RankScreen>
    with SingleTickerProviderStateMixin {
  late RankProvider _provider;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _provider = Provider.of<RankProvider>(context, listen: false);
    _tabController = TabController(length: 2, vsync: this);
    _provider.watchDevice(widget.gymId, widget.deviceId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: BrandGradientText(
          loc.leaderboardTitle,
          style: theme.textTheme.titleLarge,
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: BrandGradientText(
                loc.leaderboardRankTab,
                style: theme.textTheme.titleMedium,
              ),
            ),
            Tab(
              child: BrandGradientText(
                loc.leaderboardChallengesTab,
                style: theme.textTheme.titleMedium,
              ),
            ),
          ],
        ),
      ),
      body: Consumer<RankProvider>(
        builder: (context, prov, _) {
          return TabBarView(
            controller: _tabController,
            children: [
              ListView(
                padding: const EdgeInsets.all(AppSpacing.sm),
                children: [
                  _RankCard(
                    title: loc.rankExperience,
                    icon: const _XpMonogram(),
                    subtitle: loc.profileStatsButtonSubtitle,
                    onTap: () =>
                        Navigator.of(context).pushNamed(AppRouter.dayXp),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _RankCard(
                    title: loc.rankDeviceLevel,
                    icon: const Icon(Icons.fitness_center),
                    subtitle: loc.profileStatsButtonSubtitle,
                    onTap: () =>
                        Navigator.of(context).pushNamed(AppRouter.deviceXp),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _RankCard(
                    title: loc.rankMuscleLevel,
                    icon: const _BicepsIcon(),
                    subtitle: loc.profileStatsButtonSubtitle,
                    onTap: () =>
                        Navigator.of(context).pushNamed(AppRouter.xpOverview),
                  ),
                ],
              ),
              const ChallengeTab(),
            ],
          );
        },
      ),
    );
  }
}

class _RankCard extends StatelessWidget {
  const _RankCard({
    required this.title,
    required this.icon,
    required this.onTap,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final brandColor = brandTheme?.outline ?? theme.colorScheme.secondary;
    final secondary = theme.colorScheme.onSurface.withOpacity(0.7);

    return BrandInteractiveCard(
      onTap: onTap,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      semanticLabel: subtitle != null ? '$title, $subtitle' : title,
      uiLogEvent: 'RANK_CARD_RENDER',
      child: Row(
        children: [
          _RankIcon(child: icon),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: brandColor,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: secondary,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Icon(Icons.chevron_right, color: brandColor),
        ],
      ),
    );
  }
}

class _RankIcon extends StatelessWidget {
  const _RankIcon({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final brandColor = brandTheme?.outline ?? theme.colorScheme.secondary;
    final borderColor = theme.colorScheme.onSurface.withOpacity(0.08);
    final background = theme.scaffoldBackgroundColor;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: borderColor),
      ),
      child: IconTheme(
        data: IconThemeData(
          color: brandColor,
          size: 28,
        ),
        child: DefaultTextStyle(
          style: theme.textTheme.titleMedium?.copyWith(color: brandColor) ??
              TextStyle(color: brandColor),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _BicepsIcon extends StatelessWidget {
  const _BicepsIcon();

  @override
  Widget build(BuildContext context) {
    return const _BrandColoredEmojiIcon(
      emoji: '💪',
      size: 24,
    );
  }
}

class _BrandColoredEmojiIcon extends StatelessWidget {
  const _BrandColoredEmojiIcon({
    required this.emoji,
    required this.size,
  });

  final String emoji;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = IconTheme.of(context).color ??
        theme.extension<AppBrandTheme>()?.outline ??
        theme.colorScheme.secondary;

    return ColorFiltered(
      colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
      child: Text(
        emoji,
        style: theme.textTheme.headlineSmall?.copyWith(fontSize: size) ??
            TextStyle(fontSize: size),
      ),
    );
  }
}

class _XpMonogram extends StatelessWidget {
  const _XpMonogram();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconTheme = IconTheme.of(context);
    final size = iconTheme.size ?? AppSpacing.xl;
    final textStyle = theme.textTheme.titleMedium?.copyWith(
          color: iconTheme.color,
          fontSize: size * 0.6,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ) ??
        TextStyle(
          color: iconTheme.color,
          fontSize: size * 0.6,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        );

    return SizedBox.square(
      dimension: size,
      child: Center(
        child: Text(
          'XP',
          style: textStyle,
        ),
      ),
    );
  }
}

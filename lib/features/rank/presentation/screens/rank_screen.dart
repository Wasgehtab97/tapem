import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/core/providers/rank_provider.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/features/challenges/presentation/screens/challenge_tab.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/widgets/brand_interactive_card.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/l10n/app_localizations.dart';

/// Rank landing displayed in the "Rank" tab of the leaderboard.
class RankScreen extends ConsumerStatefulWidget {
  final String gymId;
  final String deviceId;
  const RankScreen({Key? key, required this.gymId, required this.deviceId})
    : super(key: key);

  @override
  ConsumerState<RankScreen> createState() => _RankScreenState();
}

class _RankScreenState extends ConsumerState<RankScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(rankProvider).watchDevice(widget.gymId, widget.deviceId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(rankProvider);
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final accentColor = brandTheme?.outline ?? theme.colorScheme.secondary;
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: Text(
          loc.leaderboardTitle,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.0,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withOpacity(0.8),
              borderRadius: BorderRadius.circular(AppRadius.chip),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(AppRadius.chip - 4),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              labelColor: theme.colorScheme.onPrimary,
              unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
              labelStyle: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              dividerColor: Colors.transparent,
              tabs: [
                _buildSizedTab(context, loc.leaderboardRankTab, [
                  loc.leaderboardRankTab,
                  loc.leaderboardChallengesTab,
                ]),
                _buildSizedTab(context, loc.leaderboardChallengesTab, [
                  loc.leaderboardRankTab,
                  loc.leaderboardChallengesTab,
                ]),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        color: theme.scaffoldBackgroundColor,
        child: SafeArea(
          child: TabBarView(
            controller: _tabController,
            children: [
              ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  _RankCard(
                    title: loc.rankExperience,
                    icon: const _XpMonogram(),
                    subtitle: loc.profileStatsButtonSubtitle,
                    onTap: () => Navigator.of(context).pushNamed(AppRouter.dayXp),
                    gradientStart: accentColor.withOpacity(0.1),
                    gradientEnd: accentColor.withOpacity(0.02),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _RankCard(
                    title: loc.rankDeviceLevel,
                    icon: const Icon(Icons.fitness_center),
                    subtitle: loc.profileStatsButtonSubtitle,
                    onTap: () =>
                        Navigator.of(context).pushNamed(AppRouter.deviceXp),
                    gradientStart: Colors.blue.withOpacity(0.1),
                    gradientEnd: Colors.blue.withOpacity(0.02),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _RankCard(
                    title: loc.rankMuscleLevel,
                    icon: const _BicepsIcon(),
                    subtitle: loc.profileStatsButtonSubtitle,
                    onTap: () =>
                        Navigator.of(context).pushNamed(AppRouter.xpOverview),
                    gradientStart: Colors.orange.withOpacity(0.1),
                    gradientEnd: Colors.orange.withOpacity(0.02),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _RankCard(
                    title: loc.powerliftingTitle,
                    icon: const Icon(Icons.auto_graph_rounded),
                    subtitle: loc.profileStatsButtonSubtitle,
                    onTap: () => Navigator.of(context)
                        .pushNamed(AppRouter.powerliftingLeaderboard),
                    gradientStart: accentColor.withOpacity(0.12),
                    gradientEnd: accentColor.withOpacity(0.03),
                  ),
                ],
              ),
              const ChallengeTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSizedTab(BuildContext context, String label, List<String> allLabels) {
    // This helper creates a Tab that is as wide as the widest label in allLabels.
    // It uses a Stack with invisible copies of all labels to force the width.
    return Tab(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Invisible copies of all labels to force max width
            ...allLabels.map((l) => Visibility(
                  visible: false,
                  maintainSize: true,
                  maintainAnimation: true,
                  maintainState: true,
                  child: Text(l),
                )),
            // The actual visible label
            Text(label),
          ],
        ),
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
    this.gradientStart,
    this.gradientEnd,
  });

  final String title;
  final String? subtitle;
  final Widget icon;
  final VoidCallback onTap;
  final Color? gradientStart;
  final Color? gradientEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final brandColor = brandTheme?.outline ?? theme.colorScheme.secondary;
    final secondary = theme.colorScheme.onSurface.withOpacity(0.6);

    return BrandInteractiveCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              gradientStart ?? theme.colorScheme.surface,
              gradientEnd ?? theme.colorScheme.surface.withOpacity(0.5),
            ],
          ),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
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
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
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
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                color: brandColor,
                size: 16,
              ),
            ),
          ],
        ),
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

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.onSurface.withOpacity(0.05),
        ),
      ),
      child: IconTheme(
        data: IconThemeData(
          color: brandColor,
          size: 28,
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _BicepsIcon extends StatelessWidget {
  const _BicepsIcon();

  @override
  Widget build(BuildContext context) {
    return const Text(
      '💪',
      style: TextStyle(fontSize: 24),
    );
  }
}

class _XpMonogram extends StatelessWidget {
  const _XpMonogram();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final brandColor = brandTheme?.outline ?? theme.colorScheme.secondary;

    return Text(
      'XP',
      style: theme.textTheme.titleLarge?.copyWith(
        color: brandColor,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.0,
      ),
    );
  }
}

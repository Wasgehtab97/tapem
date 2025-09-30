import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/rank_provider.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/features/challenges/presentation/screens/challenge_tab.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/widgets/brand_action_tile.dart';
import 'package:tapem/core/widgets/brand_gradient_text.dart';
import 'package:tapem/core/widgets/global_app_bar_actions.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/core/logging/elog.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: BrandGradientText(
          'Leaderboard',
          style: theme.textTheme.titleLarge,
        ),
        actions: buildGlobalAppBarActions(),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: BrandGradientText(
                'Rank',
                style: theme.textTheme.titleMedium,
              ),
            ),
            Tab(
              child: BrandGradientText(
                'Challenges',
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
                  BrandActionTile(
                    title: AppLocalizations.of(context)!.rankExperience,
                    onTap: () =>
                        Navigator.of(context).pushNamed(AppRouter.dayXp),
                    centerTitle: true,
                    showChevron: false,
                    variant: BrandActionTileVariant.outlined,
                    margin: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm),
                    uiLogEvent: 'RANK_CARD_RENDER',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  BrandActionTile(
                    title: AppLocalizations.of(context)!.rankDeviceLevel,
                    onTap: () =>
                        Navigator.of(context).pushNamed(AppRouter.deviceXp),
                    centerTitle: true,
                    showChevron: false,
                    variant: BrandActionTileVariant.outlined,
                    margin: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm),
                    uiLogEvent: 'RANK_CARD_RENDER',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  BrandActionTile(
                    title: AppLocalizations.of(context)!.rankMuscleLevel,
                    onTap: () =>
                        Navigator.of(context).pushNamed(AppRouter.xpOverview),
                    centerTitle: true,
                    showChevron: false,
                    variant: BrandActionTileVariant.outlined,
                    margin: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm),
                    uiLogEvent: 'RANK_CARD_RENDER',
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

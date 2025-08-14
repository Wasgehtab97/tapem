import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/rank_provider.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/features/challenges/presentation/screens/challenge_tab.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/widgets/brand_action_tile.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Rank'), Tab(text: 'Challenges')],
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
                    title: 'XP je Muskelgruppe',
                    onTap: () =>
                        Navigator.of(context).pushNamed(AppRouter.xpOverview),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  BrandActionTile(
                    title: 'XP je Trainingstag',
                    onTap: () =>
                        Navigator.of(context).pushNamed(AppRouter.dayXp),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  BrandActionTile(
                    title: 'XP je Gerät',
                    onTap: () =>
                        Navigator.of(context).pushNamed(AppRouter.deviceXp),
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

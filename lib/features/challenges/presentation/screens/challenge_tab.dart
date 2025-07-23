import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/gym_provider.dart';
import '../widgets/active_challenges_widget.dart';
import '../widgets/completed_challenges_widget.dart';
import '../../../../core/providers/challenge_provider.dart';

class ChallengeTab extends StatefulWidget {
  const ChallengeTab({Key? key}) : super(key: key);

  @override
  State<ChallengeTab> createState() => _ChallengeTabState();
}

class _ChallengeTabState extends State<ChallengeTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gymId = context.read<GymProvider>().currentGymId;
      final userId = context.read<AuthProvider>().userId;
      if (gymId.isNotEmpty) {
        context.read<ChallengeProvider>().watchChallenges(gymId);
      }
      if (userId != null) {
        context.read<ChallengeProvider>().watchBadges(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Aktiv'),
            Tab(text: 'Abgeschlossen'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              ActiveChallengesWidget(),
              CompletedChallengesWidget(),
            ],
          ),
        ),
      ],
    );
  }
}

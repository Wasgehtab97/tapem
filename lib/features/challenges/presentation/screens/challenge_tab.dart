import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/gym_provider.dart';
import '../widgets/active_challenges_widget.dart';
import '../widgets/completed_challenges_widget.dart';
import '../../../../core/providers/challenge_provider.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';

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

    final gymId = context.read<GymProvider>().currentGymId;
    final userId = context.read<AuthProvider>().userId;
    print('ChallengeTab init with gym: $gymId, user: $userId');

    if (gymId.isNotEmpty && userId != null) {
      context.read<ChallengeProvider>().watchChallenges(gymId, userId);
    }
    if (userId != null) {
      context.read<ChallengeProvider>().watchBadges(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final accentColor = brandTheme?.outline ?? theme.colorScheme.secondary;

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
          height: 40,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.1)),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: accentColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: accentColor.withOpacity(0.5)),
            ),
            labelColor: accentColor,
            unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
            labelStyle: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            dividerColor: Colors.transparent,
            splashBorderRadius: BorderRadius.circular(20),
              tabs: [
                _buildSizedTab(context, loc.challengeTabActive, [
                  loc.challengeTabActive,
                  loc.challengeTabCompleted,
                ]),
                _buildSizedTab(context, loc.challengeTabCompleted, [
                  loc.challengeTabActive,
                  loc.challengeTabCompleted,
                ]),
              ],
          ),
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

  Widget _buildSizedTab(BuildContext context, String label, List<String> allLabels) {
    return Tab(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            ...allLabels.map((l) => Visibility(
                  visible: false,
                  maintainSize: true,
                  maintainAnimation: true,
                  maintainState: true,
                  child: Text(l),
                )),
            Text(label),
          ],
        ),
      ),
    );
  }
}

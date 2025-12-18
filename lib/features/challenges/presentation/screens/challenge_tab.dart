import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/auth_providers.dart';
import '../../../../core/providers/challenge_provider.dart';
import '../widgets/active_challenges_widget.dart';
import '../widgets/completed_challenges_widget.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';

class ChallengeTab extends ConsumerStatefulWidget {
  const ChallengeTab({Key? key}) : super(key: key);

  @override
  ConsumerState<ChallengeTab> createState() => _ChallengeTabState();
}

class _ChallengeTabState extends ConsumerState<ChallengeTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _didSetupListen = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void _handleAuthChanged(AuthViewState? previous, AuthViewState next) {
    final gymId = next.gymCode;
    final userId = next.userId;

    if (gymId == null || gymId.isEmpty || userId == null) {
      return;
    }

    final challenges = ref.read(challengeProvider);
    challenges.watchChallenges(gymId, userId);
    challenges.watchBadges(userId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Auf Auth‑Änderungen reagieren und Challenges initial laden.
    if (!_didSetupListen) {
      _didSetupListen = true;
      // Initialer Aufruf für aktuellen Auth‑State.
      _handleAuthChanged(null, ref.read(authViewStateProvider));
      // Listener für spätere Änderungen.
      ref.listen<AuthViewState>(
        authViewStateProvider,
        _handleAuthChanged,
      );
    }

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

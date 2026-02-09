import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/core/providers/rank_provider.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/features/challenges/presentation/screens/challenge_tab.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/features/rank/presentation/widgets/ranking_ui.dart';
import 'package:tapem/features/xp/domain/experience_rank_signal_service.dart';
import 'package:tapem/l10n/app_localizations.dart';

/// Rank landing displayed in the "Rank" tab of the leaderboard.
class RankScreen extends ConsumerStatefulWidget {
  final String gymId;
  final String deviceId;
  /// True when this screen is hosted as a primary bottom-tab destination.
  /// In this mode no leading back button is shown.
  final bool isPrimaryTab;
  final VoidCallback? onExitToProfile;
  const RankScreen({
    Key? key,
    required this.gymId,
    required this.deviceId,
    this.isPrimaryTab = false,
    this.onExitToProfile,
  }) : super(key: key);

  @override
  ConsumerState<RankScreen> createState() => _RankScreenState();
}

class _RankScreenState extends ConsumerState<RankScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ExperienceRankSignalService _experienceRankSignalService =
      ExperienceRankSignalService();
  ExperienceRankSignal _experienceRankSignal =
      const ExperienceRankSignal.empty();
  bool _loadingExperienceSignal = false;
  String? _lastSignalGymId;
  String? _lastSignalUserId;

  void _handleBackPressed() {
    final onExitToProfile = widget.onExitToProfile;
    if (onExitToProfile != null) {
      onExitToProfile();
      return;
    }
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  Widget? _buildLeadingBackButton() {
    if (widget.isPrimaryTab) {
      return null;
    }
    final canPop = Navigator.of(context).canPop();
    if (!canPop && widget.onExitToProfile == null) {
      return null;
    }
    return IconButton(
      onPressed: _handleBackPressed,
      icon: const Icon(Icons.chevron_left_rounded),
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(rankProvider).watchDevice(widget.gymId, widget.deviceId);
      _refreshExperienceSignal(force: true);
    });
  }

  @override
  void didUpdateWidget(covariant RankScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gymId != widget.gymId) {
      _refreshExperienceSignal(force: true);
    }
  }

  Future<void> _refreshExperienceSignal({bool force = false}) async {
    final auth = ref.read(authViewStateProvider);
    final userId = auth.userId;
    final gymId = widget.gymId;
    if (userId == null || gymId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _experienceRankSignal = const ExperienceRankSignal.empty();
        _loadingExperienceSignal = false;
      });
      return;
    }
    if (!force && _lastSignalGymId == gymId && _lastSignalUserId == userId) {
      return;
    }
    if (mounted) {
      setState(() {
        _loadingExperienceSignal = true;
      });
    }
    final signal = await _experienceRankSignalService.fetch(
      gymId: gymId,
      userId: userId,
    );
    if (!mounted) return;
    setState(() {
      _experienceRankSignal = signal;
      _loadingExperienceSignal = false;
      _lastSignalGymId = gymId;
      _lastSignalUserId = userId;
    });
  }

  void _showCurrentRankInsight() {
    final locale = Localizations.localeOf(context);
    final isDe = locale.languageCode.toLowerCase().startsWith('de');
    final formatter = NumberFormat.decimalPattern(locale.toString());

    final title = isDe ? 'Aktueller Rang' : 'Current rank';
    final rank = _experienceRankSignal.currentRank;
    final participants = _experienceRankSignal.participantCount;
    final gap = _experienceRankSignal.xpToNextRank ?? 0;

    final body = _loadingExperienceSignal
        ? (isDe ? 'Rangdaten werden gerade geladen.' : 'Rank data is loading.')
        : rank == null || participants <= 0
        ? (isDe
              ? 'Du bist aktuell noch nicht in der Rangliste.'
              : 'You are currently not ranked yet.')
        : isDe
        ? 'Aktuell Rang #$rank von ${formatter.format(participants)}.'
        : 'Current rank #$rank of ${formatter.format(participants)}.';

    final detail =
        _loadingExperienceSignal || rank == null || rank <= 1 || gap <= 0
        ? null
        : (isDe
              ? 'Abstand zum nächsten Rang: ${formatter.format(gap)} XP'
              : 'Gap to next rank: ${formatter.format(gap)} XP');

    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final accent = brandTheme?.outline ?? theme.colorScheme.secondary;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
          child: RankingHeroCard(
            accent: accent,
            startColor: const Color(0xFF11233D),
            accentOpacity: 0.28,
            borderOpacity: 0.42,
            shadowOpacity: 0.28,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.orbitron(
                    textStyle: theme.textTheme.titleLarge,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: GoogleFonts.rajdhani(
                    textStyle: theme.textTheme.titleMedium,
                    color: Colors.white.withOpacity(0.84),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (detail != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    detail,
                    style: GoogleFonts.rajdhani(
                      textStyle: theme.textTheme.bodyMedium,
                      color: Colors.white.withOpacity(0.72),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.gymId.isEmpty || widget.deviceId.isEmpty) {
      final theme = Theme.of(context);
      return Scaffold(
        backgroundColor: const Color(0xFF0B1221),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: _buildLeadingBackButton(),
          title: Text(
            'Leaderboard',
            style: GoogleFonts.orbitron(
              textStyle: theme.textTheme.titleLarge,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: Center(
          child: Text(
            'Kein Gerät/Gym konfiguriert – bitte zuerst ein Gerät auswählen.',
            style: GoogleFonts.rajdhani(
              textStyle: theme.textTheme.titleMedium,
              color: Colors.white.withOpacity(0.84),
            ),
          ),
        ),
      );
    }

    ref.watch(rankProvider);
    final authState = ref.watch(authViewStateProvider);
    if (authState.userId != _lastSignalUserId ||
        widget.gymId != _lastSignalGymId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _refreshExperienceSignal();
      });
    }
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final accentColor = brandTheme?.outline ?? theme.colorScheme.secondary;
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1221),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: _buildLeadingBackButton(),
        title: Text(
          loc.leaderboardTitle,
          style: GoogleFonts.orbitron(
            textStyle: theme.textTheme.headlineSmall,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.4,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(74),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: _LeaderboardTopTabs(
              controller: _tabController,
              accentColor: accentColor,
              rankLabel: loc.leaderboardRankTab,
              challengesLabel: loc.leaderboardChallengesTab,
            ),
          ),
        ),
      ),
      body: RankingGradientBackground(
        child: SafeArea(
          child: TabBarView(
            controller: _tabController,
            children: [
              ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  _RankIntroCard(
                    title: 'Competitive Rankings',
                    subtitle:
                        'Steig im Gym-Ranking auf und verfolge deinen Fortschritt live.',
                    accentColor: accentColor,
                    onTap: _showCurrentRankInsight,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _RankCard(
                    title: loc.rankExperience,
                    icon: const _XpMonogram(),
                    subtitle: loc.profileStatsButtonSubtitle,
                    onTap: () =>
                        Navigator.of(context).pushNamed(AppRouter.dayXp),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _RankCard(
                    title: loc.rankDeviceLevel,
                    icon: const Icon(Icons.fitness_center),
                    subtitle: loc.profileStatsButtonSubtitle,
                    onTap: () =>
                        Navigator.of(context).pushNamed(AppRouter.deviceXp),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _RankCard(
                    title: loc.rankMuscleLevel,
                    icon: const _BicepsIcon(),
                    subtitle: loc.profileStatsButtonSubtitle,
                    onTap: () =>
                        Navigator.of(context).pushNamed(AppRouter.xpOverview),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _RankCard(
                    title: loc.powerliftingTitle,
                    icon: const Icon(Icons.auto_graph_rounded),
                    subtitle: loc.profileStatsButtonSubtitle,
                    onTap: () => Navigator.of(
                      context,
                    ).pushNamed(AppRouter.powerliftingLeaderboard),
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
}

class _LeaderboardTopTabs extends StatelessWidget {
  const _LeaderboardTopTabs({
    required this.controller,
    required this.accentColor,
    required this.rankLabel,
    required this.challengesLabel,
  });

  final TabController controller;
  final Color accentColor;
  final String rankLabel;
  final String challengesLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: controller.animation ?? controller,
      builder: (context, _) {
        final raw = controller.animation?.value ?? controller.index.toDouble();
        final normalized = raw.clamp(0.0, 1.0);
        final selectedAlignment = Alignment(-1 + (normalized * 2), 0);
        final rankActive = normalized < 0.5;

        return Container(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.chip + 4),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.surface.withOpacity(0.9),
                theme.colorScheme.surface.withOpacity(0.74),
              ],
            ),
            border: Border.all(color: Colors.white.withOpacity(0.14)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.32),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.chip + 4),
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          accentColor.withOpacity(0.1),
                          Colors.transparent,
                          accentColor.withOpacity(0.08),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(4),
                child: Align(
                  alignment: selectedAlignment,
                  child: FractionallySizedBox(
                    widthFactor: 0.5,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.chip),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            accentColor.withOpacity(0.98),
                            accentColor.withOpacity(0.74),
                          ],
                        ),
                        border: Border.all(
                          color: accentColor.withOpacity(0.95),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withOpacity(0.36),
                            blurRadius: 18,
                            offset: const Offset(0, 7),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _LeaderboardTopTabAction(
                        label: rankLabel,
                        icon: Icons.leaderboard_rounded,
                        selected: rankActive,
                        onTap: () => controller.animateTo(0),
                      ),
                    ),
                    Expanded(
                      child: _LeaderboardTopTabAction(
                        label: challengesLabel,
                        icon: Icons.emoji_events_rounded,
                        selected: !rankActive,
                        onTap: () => controller.animateTo(1),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LeaderboardTopTabAction extends StatelessWidget {
  const _LeaderboardTopTabAction({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = selected
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface.withOpacity(0.66);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.chip),
        onTap: onTap,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: textColor),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.orbitron(
                      textStyle: theme.textTheme.titleSmall,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                      height: 1,
                      color: textColor,
                    ),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surface.withOpacity(0.96),
              theme.colorScheme.surface.withOpacity(0.84),
            ],
          ),
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: brandColor.withOpacity(0.28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.34),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: brandColor.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(AppRadius.button),
                  border: Border.all(color: brandColor.withOpacity(0.42)),
                ),
                child: Center(child: icon),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.orbitron(
                        textStyle: theme.textTheme.titleMedium,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: GoogleFonts.rajdhani(
                          textStyle: theme.textTheme.bodyMedium,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_rounded, color: brandColor),
            ],
          ),
        ),
      ),
    );
  }
}

class _RankIntroCard extends StatelessWidget {
  const _RankIntroCard({
    required this.title,
    required this.subtitle,
    required this.accentColor,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDe = Localizations.localeOf(
      context,
    ).languageCode.toLowerCase().startsWith('de');
    final card = RankingHeroCard(
      accent: accentColor,
      startColor: const Color(0xFF152949),
      accentOpacity: 0.24,
      borderOpacity: 0.5,
      shadowOpacity: 0.2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.orbitron(
              textStyle: theme.textTheme.titleLarge,
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: GoogleFonts.rajdhani(
              textStyle: theme.textTheme.bodyLarge,
              color: Colors.white.withOpacity(0.82),
              fontWeight: FontWeight.w500,
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  isDe ? 'Tippen fuer Rang' : 'Tap for rank',
                  style: GoogleFonts.rajdhani(
                    textStyle: theme.textTheme.bodySmall,
                    color: Colors.white.withOpacity(0.76),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: Colors.white.withOpacity(0.8),
                ),
              ],
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: card,
      ),
    );
  }
}

class _BicepsIcon extends StatelessWidget {
  const _BicepsIcon();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final brandColor = brandTheme?.outline ?? theme.colorScheme.secondary;
    final gradient =
        brandTheme?.gradient ??
        LinearGradient(colors: [brandColor, brandColor]);

    // Emoji in Brand-Farbe einfärben: wir legen einen Shader über das Emoji,
    // sodass seine Form erhalten bleibt, aber die Farbe aus dem aktuellen
    // Theme kommt.
    return ShaderMask(
      shaderCallback: (bounds) => gradient.createShader(bounds),
      blendMode: BlendMode.srcATop,
      child: const Text('💪', style: TextStyle(fontSize: 24)),
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

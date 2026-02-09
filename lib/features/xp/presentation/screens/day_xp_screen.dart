import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/core/providers/xp_provider.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/widgets/brand_interactive_card.dart';
import 'package:tapem/features/friends/domain/models/public_profile.dart';
import 'package:tapem/features/rank/presentation/widgets/ranking_ui.dart';
import 'package:tapem/features/xp/domain/experience_rank_signal_service.dart';
import 'package:tapem/features/xp/presentation/widgets/daily_xp_card.dart';
import 'package:tapem/features/xp/presentation/widgets/xp_time_series_chart.dart';
import 'package:tapem/l10n/app_localizations.dart';

import 'leaderboard_screen.dart';

class DayXpScreen extends ConsumerStatefulWidget {
  const DayXpScreen({super.key});

  @override
  ConsumerState<DayXpScreen> createState() => _DayXpScreenState();
}

class _DayXpScreenState extends ConsumerState<DayXpScreen> {
  XpPeriod _period = XpPeriod.last30Days;
  final ExperienceRankSignalService _experienceRankSignalService =
      ExperienceRankSignalService();
  ExperienceRankSignal _experienceRankSignal =
      const ExperienceRankSignal.empty();
  bool _loadingExperienceSignal = false;
  String? _lastSignalGymId;
  String? _lastSignalUserId;

  void _openLeaderboard() {
    final loc = AppLocalizations.of(context)!;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LeaderboardScreen(title: loc.leaderboardTitle),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = ref.read(authControllerProvider);
      final xpProv = ref.read(xpProvider);
      final uid = auth.userId;
      if (uid != null) {
        xpProv.watchTrainingDays(uid);
        xpProv.watchStatsDailyXp(auth.gymCode ?? '', uid);
        _refreshExperienceSignal(gymId: auth.gymCode ?? '', userId: uid);
      }
    });
  }

  Future<void> _refreshExperienceSignal({
    required String gymId,
    required String userId,
    bool force = false,
  }) async {
    if (gymId.isEmpty || userId.isEmpty) {
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

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final auth = ref.watch(authControllerProvider);
    final xpProv = ref.watch(xpProvider);
    final locale = Localizations.localeOf(context).toString();
    final formatter = NumberFormat.decimalPattern(locale);
    final brandTheme = theme.extension<AppBrandTheme>();
    final accent = brandTheme?.outline ?? theme.colorScheme.secondary;
    final userId = auth.userId;
    final gymId = auth.gymCode ?? '';
    if (userId != null &&
        gymId.isNotEmpty &&
        (userId != _lastSignalUserId || gymId != _lastSignalGymId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _refreshExperienceSignal(gymId: gymId, userId: userId);
      });
    }

    final totalXp = xpProv.statsDailyXp;
    final level = xpProv.dailyLevel;
    final xpInLevel = xpProv.dailyLevelXp;

    final chartEntries =
        xpProv.dayListXp.entries
            .map((entry) {
              final date = DateTime.tryParse(entry.key);
              if (date == null) return null;
              return XpDailyEntry(date: date, xp: entry.value);
            })
            .whereType<XpDailyEntry>()
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    final profile = PublicProfile(
      uid: auth.userId ?? '',
      username: auth.userName ?? '',
      avatarKey: auth.avatarKey,
      primaryGymCode: auth.gymCode,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          loc.rankExperience,
          style: GoogleFonts.orbitron(
            textStyle: theme.textTheme.titleLarge,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ),
      body: RankingGradientBackground(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          children: [
            DailyXpCard(
              profile: profile,
              level: level,
              xpInLevel: xpInLevel,
              totalXp: totalXp,
              numberFormat: formatter,
              margin: EdgeInsets.zero,
            ),
            const SizedBox(height: AppSpacing.md),
            _LeaderboardCallToAction(
              title: loc.leaderboardTitle,
              subtitle: loc.profileStatsButtonSubtitle,
              onTap: _openLeaderboard,
            ),
            const SizedBox(height: AppSpacing.md),
            RankingNextRankSignalCard(
              accent: accent,
              rank: _experienceRankSignal.currentRank,
              xpToNextRank: _experienceRankSignal.xpToNextRank,
              participantCount: _experienceRankSignal.participantCount,
              loading: _loadingExperienceSignal,
            ),
            const SizedBox(height: AppSpacing.md),
            RankingSurfacePanel(
              accent: accent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'XP Trend',
                    style: GoogleFonts.orbitron(
                      textStyle: theme.textTheme.titleMedium,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Gesamt-XP als Verlaufskurve: jeder Trainingstag schiebt dich sichtbar nach oben.',
                    style: GoogleFonts.rajdhani(
                      textStyle: theme.textTheme.bodyMedium,
                      color: theme.colorScheme.onSurface.withOpacity(0.66),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Der Startwert zeigt deinen XP-Stand zu Beginn des gewählten Zeitraums. Gesamt endet am letzten XP-Event.',
                    style: GoogleFonts.rajdhani(
                      textStyle: theme.textTheme.bodySmall,
                      color: theme.colorScheme.onSurface.withOpacity(0.56),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _PeriodSwitch(
                    selected: _period,
                    onSelected: (period) {
                      setState(() {
                        _period = period;
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  XpTimeSeriesChart(
                    dailyXp: chartEntries,
                    period: _period,
                    dateFormatter: DateFormat.Md(locale),
                    referenceDate: DateTime.now(),
                    anchorTotalXp: totalXp,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodSwitch extends StatelessWidget {
  const _PeriodSwitch({required this.selected, required this.onSelected});

  final XpPeriod selected;
  final ValueChanged<XpPeriod> onSelected;

  @override
  Widget build(BuildContext context) {
    final isDe = Localizations.localeOf(
      context,
    ).languageCode.toLowerCase().startsWith('de');
    final options = <(XpPeriod, String)>[
      (XpPeriod.last7Days, isDe ? '7 Tage' : '7 Days'),
      (XpPeriod.last30Days, isDe ? '30 Tage' : '30 Days'),
      (XpPeriod.total, isDe ? 'Gesamt' : 'All-time'),
    ];

    return Row(
      children: options.map((option) {
        final isActive = option.$1 == selected;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: option == options.last ? 0 : AppSpacing.xs,
            ),
            child: RankingSegmentChip(
              label: option.$2,
              selected: isActive,
              accent: Theme.of(context).colorScheme.primary,
              onTap: () => onSelected(option.$1),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _LeaderboardCallToAction extends StatelessWidget {
  const _LeaderboardCallToAction({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final brandColor = brandTheme?.outline ?? theme.colorScheme.secondary;

    return BrandInteractiveCard(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      padding: EdgeInsets.zero,
      child: Container(
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
          border: Border.all(color: brandColor.withOpacity(0.24)),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: brandColor.withOpacity(0.14),
                borderRadius: BorderRadius.circular(AppRadius.button),
                border: Border.all(color: brandColor.withOpacity(0.4)),
              ),
              child: const Icon(Icons.leaderboard),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.orbitron(
                      textStyle: theme.textTheme.titleSmall,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.rajdhani(
                      textStyle: theme.textTheme.bodySmall,
                      color: theme.colorScheme.onSurface.withOpacity(0.66),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_rounded, color: brandColor),
          ],
        ),
      ),
    );
  }
}

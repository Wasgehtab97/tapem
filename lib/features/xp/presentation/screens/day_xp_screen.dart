import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/features/rank/domain/services/level_service.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/xp_provider.dart';
import 'package:tapem/features/friends/domain/models/public_profile.dart';
import 'package:tapem/features/friends/presentation/widgets/friend_list_tile.dart';
import '../widgets/xp_time_series_chart.dart';
import 'leaderboard_screen.dart';
import 'package:tapem/l10n/app_localizations.dart';

class DayXpScreen extends StatefulWidget {
  const DayXpScreen({Key? key}) : super(key: key);

  @override
  State<DayXpScreen> createState() => _DayXpScreenState();
}

class _DayXpScreenState extends State<DayXpScreen> {
  void _openLeaderboard() {
    final loc = AppLocalizations.of(context)!;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => LeaderboardScreen(
              title: loc.leaderboardTitle,
            ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    final xpProv = context.read<XpProvider>();
    final uid = auth.userId;
    if (uid != null) {
      xpProv.watchTrainingDays(uid);
      xpProv.watchStatsDailyXp(auth.gymCode ?? '', uid);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final xpProv = context.watch<XpProvider>();
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final highlightGradient = brandTheme?.gradient ?? AppGradients.brandGradient;
    final gradientColors = brandTheme?.gradient.colors ?? AppGradients.brandGradient.colors;
    final progressColor = gradientColors.first;
    final xpPerLevel = LevelService.xpPerLevel;
    final userLevel = xpProv.dailyLevel;
    final userXpInLevel = xpProv.dailyLevelXp;
    final userProgress = userLevel >= LevelService.maxLevel
        ? 1.0
        : userXpInLevel / xpPerLevel;
    final xpRemaining = userLevel >= LevelService.maxLevel ? 0 : xpPerLevel - userXpInLevel;
    final locale = Localizations.localeOf(context).toString();
    final formatter = NumberFormat.decimalPattern(locale);

    Widget buildCurrentUserCard() {
      final profile = PublicProfile(
        uid: auth.userId ?? '',
        username: auth.userName ?? '',
        avatarKey: auth.avatarKey,
        primaryGymCode: auth.gymCode,
      );
      final totalXp = formatter.format(xpProv.statsDailyXp);
      final xpLabel = '${formatter.format(userXpInLevel)} / ${formatter.format(xpPerLevel)} XP';
      final remainingText = userLevel >= LevelService.maxLevel
          ? 'Maximallevel erreicht'
          : '${formatter.format(xpRemaining)} XP bis Level ${userLevel + 1}';
      final themed = theme.copyWith(
        textTheme: theme.textTheme.apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        colorScheme: theme.colorScheme.copyWith(onSurface: Colors.white),
      );

      return Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          gradient: highlightGradient,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Theme(
            data: themed,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FriendListTile(
                  profile: profile,
                  subtitle: 'Level $userLevel',
                  trailing: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        xpLabel,
                        style: theme.textTheme.labelLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ) ??
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Text(
                        'Gesamt $totalXp XP',
                        style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                            ) ??
                            const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: userProgress.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: Colors.white.withOpacity(0.25),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  remainingText,
                  style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ) ??
                      const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Erfahrung'),
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard),
            tooltip: 'Rangliste',
            onPressed: _openLeaderboard,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        children: [
          const SizedBox(height: AppSpacing.sm),
          buildCurrentUserCard(),
        ],
      ),
    );
  }
}

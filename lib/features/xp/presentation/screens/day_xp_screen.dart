import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

class DayXpScreen extends StatefulWidget {
  const DayXpScreen({Key? key}) : super(key: key);

  @override
  State<DayXpScreen> createState() => _DayXpScreenState();
}

class _DayXpScreenState extends State<DayXpScreen> {
  StreamSubscription? _lbSub;
  List<LeaderboardEntry> _lbEntries = [];

  void _openLeaderboard() {
    final auth = context.read<AuthProvider>();
    final gymId = auth.gymCode ?? '';

    Future<List<LeaderboardEntry>> fetchEntries(XpPeriod period) async {
      if (gymId.isEmpty) {
        return [];
      }
      final fs = FirebaseFirestore.instance;
      final snap =
          await fs.collection('gyms').doc(gymId).collection('users').get();
      final List<LeaderboardEntry> data = [];
      for (final doc in snap.docs) {
        final uid = doc.id;
        final userDoc = await fs.collection('users').doc(uid).get();
        if (!(userDoc.data()?['showInLeaderboard'] as bool? ?? true)) {
          continue;
        }
        final profile =
            PublicProfile.fromMap(uid, userDoc.data() ?? <String, dynamic>{});
        final statsDoc =
            await fs
                .collection('gyms')
                .doc(gymId)
                .collection('users')
                .doc(uid)
                .collection('rank')
                .doc('stats')
                .get();
        final xp = statsDoc.data()?['dailyXP'] as int? ?? 0;
        data.add(LeaderboardEntry(profile: profile, xp: xp));
      }
      return data;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => LeaderboardScreen(
              title: 'Rangliste',
              fetchEntries: fetchEntries,
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
      _listenLeaderboard(auth.gymCode ?? '');
    }
  }

  void _listenLeaderboard(String gymId) {
    if (gymId.isEmpty) {
      return;
    }
    final fs = FirebaseFirestore.instance;
    debugPrint('👀 listen leaderboard gymId=$gymId');
    _lbSub = fs
        .collection('gyms')
        .doc(gymId)
        .collection('users')
        .snapshots()
        .listen((snap) async {
          debugPrint('📥 leaderboard snapshot users=${snap.docs.length}');
          final List<LeaderboardEntry> data = [];
          for (final doc in snap.docs) {
            final uid = doc.id;
            final userDoc = await fs.collection('users').doc(uid).get();
            if (!(userDoc.data()?['showInLeaderboard'] as bool? ?? true)) {
              continue;
            }
            final profile =
                PublicProfile.fromMap(uid, userDoc.data() ?? <String, dynamic>{});
            final statsDoc =
                await fs
                    .collection('gyms')
                    .doc(gymId)
                    .collection('users')
                    .doc(uid)
                    .collection('rank')
                    .doc('stats')
                    .get();
            final xp = statsDoc.data()?['dailyXP'] as int? ?? 0;
            data.add(LeaderboardEntry(profile: profile, xp: xp));
          }
          data.sort((a, b) => b.xp.compareTo(a.xp));
          debugPrint('🏆 leaderboard entries=${data.length}');
          setState(() => _lbEntries = data);
        });
  }

  _LevelProgress _resolveLevelProgress(int totalXp) {
    final xpPerLevel = LevelService.xpPerLevel;
    final maxLevel = LevelService.maxLevel;
    var level = (totalXp ~/ xpPerLevel) + 1;
    if (level > maxLevel) {
      level = maxLevel;
    }
    var xpInLevel = totalXp % xpPerLevel;
    if (level >= maxLevel) {
      xpInLevel = 0;
    }
    final progress = level >= maxLevel ? 1.0 : xpInLevel / xpPerLevel;
    return _LevelProgress(level: level, xpInLevel: xpInLevel, progress: progress);
  }

  @override
  void dispose() {
    _lbSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final xpProv = context.watch<XpProvider>();
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final borderColor =
        brandTheme?.outline.withOpacity(0.22) ?? theme.colorScheme.onSurface.withOpacity(0.12);
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

    Widget buildSurfaceCard(
      Widget child, {
      EdgeInsetsGeometry? padding,
      EdgeInsetsGeometry? margin,
    }) {
      return Container(
        margin: margin ??
            const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.32),
              blurRadius: 28,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(AppSpacing.sm),
          child: child,
        ),
      );
    }

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

    Widget buildLeaderboardCard() {
      final maxRank = _lbEntries.length < 10 ? _lbEntries.length : 10;
      if (maxRank == 0) {
        return buildSurfaceCard(
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Text(
                'Keine Ranglisten-Daten',
                style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
              ),
            ),
          ),
        );
      }

      return buildSurfaceCard(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top 10',
              style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ..._lbEntries.asMap().entries.take(maxRank).map((entry) {
              final rank = entry.key + 1;
              final data = entry.value;
              final progress = _resolveLevelProgress(data.xp);
              final progressValue = progress.progress.clamp(0.0, 1.0);
              final xpLabel =
                  '${formatter.format(progress.xpInLevel)} / ${formatter.format(xpPerLevel)} XP';
              final isLast = entry.key == maxRank - 1;
              return Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FriendListTile(
                      profile: data.profile,
                      subtitle: '#$rank',
                      trailing: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Level ${progress.level}',
                            style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          Text(
                            xpLabel,
                            style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progressValue,
                        minHeight: 4,
                        backgroundColor:
                            theme.colorScheme.onSurface.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
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
          buildLeaderboardCard(),
        ],
      ),
    );
  }
}

class _LevelProgress {
  final int level;
  final int xpInLevel;
  final double progress;

  const _LevelProgress({
    required this.level,
    required this.xpInLevel,
    required this.progress,
  });
}

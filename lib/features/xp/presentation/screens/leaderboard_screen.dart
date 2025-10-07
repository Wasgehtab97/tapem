import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/features/friends/domain/models/public_profile.dart';
import 'package:tapem/features/friends/presentation/widgets/friend_list_tile.dart';
import 'package:tapem/features/friends/providers/friends_provider.dart';
import 'package:tapem/features/rank/domain/services/level_service.dart';
import 'package:tapem/l10n/app_localizations.dart';
import '../../../../core/providers/auth_provider.dart';

class LeaderboardEntry {
  final PublicProfile profile;
  final int xp;

  const LeaderboardEntry({
    required this.profile,
    required this.xp,
  });
}

enum _LeaderboardMode { gym, friends }

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key, required this.title});

  final String title;

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  _LeaderboardMode _mode = _LeaderboardMode.gym;
  List<LeaderboardEntry>? _gymEntries;
  List<LeaderboardEntry>? _friendEntries;
  bool _loadingGym = false;
  bool _loadingFriends = false;
  AuthProvider? _authProvider;
  FriendsProvider? _friendsProvider;

  Future<int> _loadDailyXpAcrossGyms(String uid, Set<String> gymIds) async {
    if (gymIds.isEmpty) {
      return 0;
    }
    final fs = FirebaseFirestore.instance;
    final xpValues = await Future.wait(gymIds.map((gymId) async {
      try {
        final statsDoc = await fs
            .collection('gyms')
            .doc(gymId)
            .collection('users')
            .doc(uid)
            .collection('rank')
            .doc('stats')
            .get();
        return statsDoc.data()?['dailyXP'] as int? ?? 0;
      } on FirebaseException catch (error, stack) {
        debugPrint(
          'Failed to load rank stats for user=$uid gym=$gymId: ${error.message}',
        );
        debugPrint('$stack');
        return 0;
      } catch (error, stack) {
        debugPrint(
          'Unexpected error loading rank stats for user=$uid gym=$gymId: $error',
        );
        debugPrint('$stack');
        return 0;
      }
    }));
    return xpValues.fold<int>(0, (sum, value) => sum + value);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshGym();
      _refreshFriends();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthProvider>();
    if (!identical(auth, _authProvider)) {
      _authProvider?.removeListener(_handleAuthChanged);
      _authProvider = auth;
      _authProvider?.addListener(_handleAuthChanged);
    }
    final friends = context.read<FriendsProvider>();
    if (!identical(friends, _friendsProvider)) {
      _friendsProvider?.removeListener(_handleFriendsChanged);
      _friendsProvider = friends;
      _friendsProvider?.addListener(_handleFriendsChanged);
    }
  }

  void _handleAuthChanged() {
    _refreshGym();
    _refreshFriends();
  }

  void _handleFriendsChanged() {
    _refreshFriends();
  }

  Future<void> _refreshGym() async {
    final auth = _authProvider ?? context.read<AuthProvider>();
    final gymId = auth.gymCode ?? '';
    if (gymId.isEmpty) {
      if (!mounted) return;
      setState(() => _gymEntries = const []);
      return;
    }
    if (mounted) {
      setState(() => _loadingGym = true);
    }
    try {
      final fs = FirebaseFirestore.instance;
      final snap = await fs.collection('gyms').doc(gymId).collection('users').get();
      final futures = snap.docs.map((doc) async {
        final uid = doc.id;
        final userDoc = await fs.collection('users').doc(uid).get();
        final userData = userDoc.data();
        if (userData == null || !(userData['showInLeaderboard'] as bool? ?? true)) {
          return null;
        }
        final profile = PublicProfile.fromMap(uid, userData);
        final statsDoc = await fs
            .collection('gyms')
            .doc(gymId)
            .collection('users')
            .doc(uid)
            .collection('rank')
            .doc('stats')
            .get();
        final xp = statsDoc.data()?['dailyXP'] as int? ?? 0;
        return LeaderboardEntry(profile: profile, xp: xp);
      });
      final entries = (await Future.wait(futures))
          .whereType<LeaderboardEntry>()
          .toList()
        ..sort((a, b) => b.xp.compareTo(a.xp));
      if (!mounted) return;
      setState(() => _gymEntries = entries.take(10).toList());
    } catch (error, stack) {
      debugPrint('Failed to load gym leaderboard: $error');
      debugPrint('$stack');
      if (!mounted) return;
      setState(() => _gymEntries = const []);
    } finally {
      if (mounted) {
        setState(() => _loadingGym = false);
      }
    }
  }

  Future<void> _refreshFriends() async {
    final auth = _authProvider ?? context.read<AuthProvider>();
    final friendsProv = _friendsProvider ?? context.read<FriendsProvider>();
    final userId = auth.userId;
    if (userId == null) {
      if (!mounted) return;
      setState(() => _friendEntries = const []);
      return;
    }
    if (mounted) {
      setState(() => _loadingFriends = true);
    }
    try {
      final fs = FirebaseFirestore.instance;
      final friendIds = {
        for (final f in friendsProv.friends) f.friendUid,
        userId,
      };
      final futures = friendIds.map((uid) async {
        final userDoc = await fs.collection('users').doc(uid).get();
        final userData = userDoc.data();
        if (userData == null || !(userData['showInLeaderboard'] as bool? ?? true)) {
          return null;
        }
        final profile = PublicProfile.fromMap(uid, userData);
        final gymCodes = (userData['gymCodes'] as List<dynamic>? ?? const [])
            .whereType<String>()
            .where((code) => code.isNotEmpty);
        final candidateGyms = <String>{
          if ((profile.primaryGymCode ?? '').isNotEmpty) profile.primaryGymCode!,
          ...gymCodes,
        };
        if (candidateGyms.isEmpty) {
          final fallbackGym = auth.gymCode;
          if (fallbackGym != null && fallbackGym.isNotEmpty) {
            candidateGyms.add(fallbackGym);
          }
        }
        final xp = await _loadDailyXpAcrossGyms(uid, candidateGyms);
        return LeaderboardEntry(profile: profile, xp: xp);
      });
      final entries = (await Future.wait(futures))
          .whereType<LeaderboardEntry>()
          .toList()
        ..sort((a, b) => b.xp.compareTo(a.xp));
      if (!mounted) return;
      setState(() => _friendEntries = entries);
    } catch (error, stack) {
      debugPrint('Failed to load friends leaderboard: $error');
      debugPrint('$stack');
      if (!mounted) return;
      setState(() => _friendEntries = const []);
    } finally {
      if (mounted) {
        setState(() => _loadingFriends = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final progressColor =
        brandTheme?.gradient.colors.first ?? theme.colorScheme.primary;
    final isGym = _mode == _LeaderboardMode.gym;
    final entries = isGym ? _gymEntries : _friendEntries;
    final isLoading = isGym ? _loadingGym : _loadingFriends;

    Widget buildContent() {
      if (isLoading) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      if (entries == null || entries.isEmpty) {
        final emptyText = isGym
            ? loc.leaderboardEmptyGym
            : loc.leaderboardEmptyFriends;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Center(
            child: Text(
              emptyText,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      }
      return _LeaderboardList(
        entries: entries,
        progressColor: progressColor,
        title: isGym ? loc.leaderboardGymCardTitle : loc.leaderboardFriendsCardTitle,
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: RefreshIndicator(
        onRefresh: isGym ? _refreshGym : _refreshFriends,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.md,
          ),
          children: [
            Center(
              child: ToggleButtons(
                borderRadius: BorderRadius.circular(AppRadius.button),
                onPressed: (index) {
                  setState(() {
                    _mode = index == 0
                        ? _LeaderboardMode.gym
                        : _LeaderboardMode.friends;
                  });
                },
                isSelected: [isGym, !isGym],
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: Text(loc.leaderboardGymTabLabel),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: Text(loc.leaderboardFriendsTabLabel),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            buildContent(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _authProvider?.removeListener(_handleAuthChanged);
    _friendsProvider?.removeListener(_handleFriendsChanged);
    super.dispose();
  }
}

class _LeaderboardList extends StatelessWidget {
  const _LeaderboardList({
    required this.entries,
    required this.progressColor,
    required this.title,
  });

  final List<LeaderboardEntry> entries;
  final Color progressColor;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final xpPerLevel = LevelService.xpPerLevel;
    final locale = Localizations.localeOf(context).toString();
    final formatter = NumberFormat.decimalPattern(locale);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: theme.colorScheme.onSurface.withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...entries.asMap().entries.map((entry) {
              final rank = entry.key + 1;
              final data = entry.value;
              final progress = _resolveLevelProgress(data.xp);
              final xpLabel =
                  '${formatter.format(progress.xpInLevel)} / ${formatter.format(xpPerLevel)} XP';
              final progressValue = progress.progress.clamp(0.0, 1.0);
              final isLast = rank == entries.length;

              return Padding(
                padding: EdgeInsets.only(
                  bottom: isLast ? 0 : AppSpacing.sm,
                ),
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
                        valueColor:
                            AlwaysStoppedAnimation<Color>(progressColor),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
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
  return _LevelProgress(
    level: level,
    xpInLevel: xpInLevel,
    progress: progress,
  );
}

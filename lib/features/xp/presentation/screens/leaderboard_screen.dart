import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:intl/intl.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/features/friends/domain/models/public_profile.dart';
import 'package:tapem/features/friends/presentation/widgets/friend_list_tile.dart';
import 'package:tapem/features/friends/providers/friends_riverpod.dart';
import 'package:tapem/features/rank/domain/services/level_service.dart';
import 'package:tapem/l10n/app_localizations.dart';
import '../../../../core/providers/auth_providers.dart';

class LeaderboardEntry {
  final PublicProfile profile;
  final _XpTotals totals;

  const LeaderboardEntry({
    required this.profile,
    required this.totals,
  });

  int xpForScope(LeaderboardScope scope) => totals.forScope(scope);
}

class _XpTotals {
  const _XpTotals({
    required this.overall,
    required this.seasonXp,
  });

  final int overall;
  final Map<String, int> seasonXp;

  int forScope(LeaderboardScope scope) {
    switch (scope) {
      case LeaderboardScope.overall:
        return overall;
      case LeaderboardScope.season2025:
        return seasonXp['2025'] ?? 0;
      case LeaderboardScope.season2026:
        return seasonXp['2026'] ?? 0;
    }
  }

  _XpTotals operator +(_XpTotals other) {
    return _XpTotals(
      overall: overall + other.overall,
      seasonXp: {
        '2025': (seasonXp['2025'] ?? 0) + (other.seasonXp['2025'] ?? 0),
        '2026': (seasonXp['2026'] ?? 0) + (other.seasonXp['2026'] ?? 0),
      },
    );
  }
}

enum _LeaderboardMode { gym, friends }

enum LeaderboardScope { overall, season2025, season2026 }

class LeaderboardScreen extends riverpod.ConsumerStatefulWidget {
  const LeaderboardScreen({super.key, required this.title});

  final String title;

  @override
  riverpod.ConsumerState<LeaderboardScreen> createState() =>
      _LeaderboardScreenState();
}

class _LeaderboardScreenState extends riverpod.ConsumerState<LeaderboardScreen> {
  _LeaderboardMode _mode = _LeaderboardMode.gym;
  LeaderboardScope _scope = LeaderboardScope.overall;
  List<LeaderboardEntry>? _gymEntries;
  List<LeaderboardEntry>? _friendEntries;
  bool _loadingGym = false;
  bool _loadingFriends = false;
  int _selectedLevel = 1;
  static const _XpTotals _zeroTotals =
      _XpTotals(overall: 0, seasonXp: {'2025': 0, '2026': 0});

  Future<_XpTotals> _loadXpTotalsAcrossGyms(String uid, Set<String> gymIds) async {
    if (gymIds.isEmpty) {
      return _zeroTotals;
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
        return _parseXpTotals(statsDoc.data());
      } on FirebaseException catch (error, stack) {
        debugPrint(
          'Failed to load rank stats for user=$uid gym=$gymId: ${error.message}',
        );
        debugPrint('$stack');
        return _zeroTotals;
      } catch (error, stack) {
        debugPrint(
          'Unexpected error loading rank stats for user=$uid gym=$gymId: $error',
        );
        debugPrint('$stack');
        return _zeroTotals;
      }
    }));
    return xpValues.fold<_XpTotals>(
      _zeroTotals,
      (total, value) => total + value,
    );
  }

  _XpTotals _parseXpTotals(Map<String, dynamic>? data) {
    final overall = (data?['dailyXP'] as num?)?.toInt() ?? 0;
    final seasonRaw = data?['seasonXP'] as Map<String, dynamic>? ?? const {};

    return _XpTotals(
      overall: overall,
      seasonXp: {
        '2025': (seasonRaw['2025'] as num?)?.toInt() ?? overall,
        '2026': (seasonRaw['2026'] as num?)?.toInt() ?? 0,
      },
    );
  }

  @override
  void initState() {
    super.initState();
    // Ensure initial data is loaded even if the AuthProvider does not emit
    // a change event while this screen is visible.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refreshGym();
      _refreshFriends();
    });
  }

  void _updateSelectedLevel(int level) {
    setState(() {
      final maxLevel = LevelService.maxLevel;
      if (level < 1) {
        _selectedLevel = 1;
      } else if (level > maxLevel) {
        _selectedLevel = maxLevel;
      } else {
        _selectedLevel = level;
      }
    });
  }

  Future<void> _refreshGym() async {
    final auth = ref.read(authViewStateProvider);
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
        final showInLeaderboard =
            userData?['showInLeaderboard'] as bool? ?? true;
        final role = userData?['role'] as String?;
        if (userData == null ||
            !showInLeaderboard ||
            role == 'admin') {
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
        final totals = _parseXpTotals(statsDoc.data());
        return LeaderboardEntry(profile: profile, totals: totals);
      });
      final entries = (await Future.wait(futures))
          .whereType<LeaderboardEntry>()
          .toList()
        ..sort(
          (a, b) => b
              .xpForScope(LeaderboardScope.overall)
              .compareTo(a.xpForScope(LeaderboardScope.overall)),
        );
      if (!mounted) return;
      setState(() => _gymEntries = entries);
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
    final auth = ref.read(authViewStateProvider);
    final friendsState = ref.read(friendsProvider);
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
        for (final f in friendsState.friends) f.friendUid,
        userId,
      };
      final futures = friendIds.map((uid) async {
        final userDoc = await fs.collection('users').doc(uid).get();
        final userData = userDoc.data();
        final showInLeaderboard =
            userData?['showInLeaderboard'] as bool? ?? true;
        final role = userData?['role'] as String?;
        if (userData == null ||
            !showInLeaderboard ||
            role == 'admin') {
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
        final totals = await _loadXpTotalsAcrossGyms(uid, candidateGyms);
        return LeaderboardEntry(profile: profile, totals: totals);
      });
      final entries = (await Future.wait(futures))
          .whereType<LeaderboardEntry>()
          .toList()
        ..sort(
          (a, b) => b
              .xpForScope(LeaderboardScope.overall)
              .compareTo(a.xpForScope(LeaderboardScope.overall)),
        );
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

  List<LeaderboardEntry> _sortedEntriesForScope(
    List<LeaderboardEntry> entries,
    LeaderboardScope scope,
  ) {
    final sorted = [...entries];
    sorted.sort((a, b) {
      final xpA = a.xpForScope(scope);
      final xpB = b.xpForScope(scope);
      if (xpA == xpB) {
        return a.profile.safeLower.compareTo(b.profile.safeLower);
      }
      return xpB.compareTo(xpA);
    });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthViewState>(
      authViewStateProvider,
      (_, __) {
        _refreshGym();
        _refreshFriends();
      },
    );
    ref.listen<FriendsState>(
      friendsProvider,
      (previous, next) {
        final prevIds = previous?.friends.map((f) => f.friendUid).toSet();
        final nextIds = next.friends.map((f) => f.friendUid).toSet();
        if (prevIds != nextIds) {
          _refreshFriends();
        }
      },
    );

    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final progressColor =
        brandTheme?.gradient.colors.first ?? theme.colorScheme.primary;
    final isGym = _mode == _LeaderboardMode.gym;
    final sourceEntries = isGym ? _gymEntries : _friendEntries;
    final isLoading = isGym ? _loadingGym : _loadingFriends;

    String scopeLabel(LeaderboardScope scope) {
      switch (scope) {
        case LeaderboardScope.overall:
          return 'Overall';
        case LeaderboardScope.season2025:
          return 'Season 25';
        case LeaderboardScope.season2026:
          return 'Season 26';
      }
    }

    Widget buildContent() {
      if (isLoading) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      if (sourceEntries == null || sourceEntries.isEmpty) {
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
      final entries = _sortedEntriesForScope(sourceEntries, _scope);
      final currentUserId =
          ref.watch(authViewStateProvider).userId;
      return _LevelLeaderboardList(
        entries: entries,
        scope: _scope,
        progressColor: progressColor,
        title: isGym ? loc.leaderboardGymCardTitle : loc.leaderboardFriendsCardTitle,
        selectedLevel: _selectedLevel,
        onLevelChanged: _updateSelectedLevel,
        currentUserId: currentUserId,
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
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.xs.toDouble(),
              runSpacing: AppSpacing.xs.toDouble(),
              children: LeaderboardScope.values.map((scope) {
                final selected = _scope == scope;
                return ChoiceChip(
                  label: Text(scopeLabel(scope)),
                  selected: selected,
                  onSelected: (_) => setState(() => _scope = scope),
                  selectedColor: progressColor,
                  labelStyle: theme.textTheme.bodySmall?.copyWith(
                    color: selected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  backgroundColor:
                      theme.colorScheme.onSurface.withOpacity(0.04),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.chip - 4),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.md),
            buildContent(),
          ],
        ),
      ),
    );
  }

}

class _LevelLeaderboardList extends StatelessWidget {
  const _LevelLeaderboardList({
    required this.entries,
    required this.scope,
    required this.progressColor,
    required this.title,
    required this.selectedLevel,
    required this.onLevelChanged,
    this.currentUserId,
  });

  final List<LeaderboardEntry> entries;
  final LeaderboardScope scope;
  final Color progressColor;
  final String title;
  final int selectedLevel;
  final ValueChanged<int> onLevelChanged;
  final String? currentUserId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final xpPerLevel = LevelService.xpPerLevel;
    final maxLevel = LevelService.maxLevel;
    final locale = Localizations.localeOf(context).toString();
    final formatter = NumberFormat.decimalPattern(locale);

    final levelEntries = <int, List<_LevelledEntry>>{};
    for (final entry in entries) {
      final progress = _resolveLevelProgress(entry.xpForScope(scope));
      final level = progress.level;
      final xpInLevel = progress.xpInLevel;
      final bucket = levelEntries.putIfAbsent(level, () => []);
      bucket.add(
        _LevelledEntry(
          profile: entry.profile,
          level: level,
          xpInLevel: xpInLevel,
        ),
      );
    }

    final clampedSelectedLevel = selectedLevel.clamp(1, maxLevel) as int;
    final currentLevelEntries =
        (levelEntries[clampedSelectedLevel] ?? const <_LevelledEntry>[])
            .toList()
          ..sort((a, b) {
            final xpCompare = b.xpInLevel.compareTo(a.xpInLevel);
            if (xpCompare != 0) return xpCompare;
            return a.profile.safeLower.compareTo(b.profile.safeLower);
          });

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
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: maxLevel,
                itemBuilder: (context, index) {
                  final level = index + 1;
                  final isSelected = level == clampedSelectedLevel;
                  return Padding(
                    padding: EdgeInsets.only(
                      right: index == maxLevel - 1 ? 0 : AppSpacing.xs,
                    ),
                    child: ChoiceChip(
                      label: Text('Lvl $level'),
                      selected: isSelected,
                      onSelected: (_) => onLevelChanged(level),
                      selectedColor: progressColor,
                      labelStyle: theme.textTheme.bodySmall?.copyWith(
                        color: isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurface,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      backgroundColor:
                          theme.colorScheme.onSurface.withOpacity(0.04),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppRadius.chip - 4),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Level $clampedSelectedLevel',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${formatter.format(xpPerLevel)} XP pro Level',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Divider(
              color: theme.colorScheme.onSurface.withOpacity(0.08),
              height: 1,
            ),
            if (currentLevelEntries.isEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: Text(
                  'Noch keine Ranglisten-Daten.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color:
                        theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: AppSpacing.sm),
              ..._buildRows(
                context: context,
                entries: currentLevelEntries,
                formatter: formatter,
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildRows({
    required BuildContext context,
    required List<_LevelledEntry> entries,
    required NumberFormat formatter,
  }) {
    final theme = Theme.of(context);
    final widgets = <Widget>[];

    int index = 0;
    int? previousXp;
    int previousRank = 0;

    for (final entry in entries) {
      index++;
      int rank;
      if (previousXp == null || previousXp != entry.xpInLevel) {
        rank = index;
      } else {
        rank = previousRank;
      }
      previousXp = entry.xpInLevel;
      previousRank = rank;

      final isCurrentUser =
          currentUserId != null && entry.profile.uid == currentUserId;

      widgets.add(
        Container(
          margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs / 2),
          decoration: BoxDecoration(
            gradient: isCurrentUser
                ? LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      progressColor.withOpacity(0.35),
                      progressColor.withOpacity(0.05),
                    ],
                  )
                : null,
            color: isCurrentUser
                ? null
                : theme.colorScheme.onSurface.withOpacity(0.02),
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: isCurrentUser
                  ? progressColor.withOpacity(0.8)
                  : theme.colorScheme.onSurface.withOpacity(0.06),
            ),
            boxShadow: isCurrentUser
                ? [
                    BoxShadow(
                      color: progressColor.withOpacity(0.45),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [],
          ),
          child: FriendListTile(
            profile: entry.profile,
            subtitle: isCurrentUser ? '#$rank · Du' : '#$rank',
            trailing: Text(
              '${formatter.format(entry.xpInLevel)} XP',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isCurrentUser
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
      );
    }

    return widgets;
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

class _LevelledEntry {
  final PublicProfile profile;
  final int level;
  final int xpInLevel;

  const _LevelledEntry({
    required this.profile,
    required this.level,
    required this.xpInLevel,
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

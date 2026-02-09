import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/features/friends/domain/models/public_profile.dart';
import 'package:tapem/features/friends/presentation/widgets/friend_list_tile.dart';
import 'package:tapem/features/rank/domain/services/level_service.dart';
import 'package:tapem/features/rank/presentation/widgets/ranking_ui.dart';
import 'package:tapem/l10n/app_localizations.dart';

class DeviceXpLeaderboardScreen extends ConsumerStatefulWidget {
  const DeviceXpLeaderboardScreen({
    super.key,
    required this.gymId,
    required this.deviceId,
    required this.deviceName,
  });

  final String gymId;
  final String deviceId;
  final String deviceName;

  @override
  ConsumerState<DeviceXpLeaderboardScreen> createState() =>
      _DeviceXpLeaderboardScreenState();
}

class _DeviceXpLeaderboardScreenState
    extends ConsumerState<DeviceXpLeaderboardScreen> {
  List<_DeviceLeaderboardEntry>? _entries;
  bool _loading = false;
  int _selectedLevel = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadEntries();
    });
  }

  Future<void> _loadEntries() async {
    if (widget.gymId.isEmpty) {
      setState(() {
        _entries = const [];
      });
      return;
    }
    setState(() {
      _loading = true;
    });
    try {
      final fs = FirebaseFirestore.instance;
      final snap = await fs
          .collection('gyms')
          .doc(widget.gymId)
          .collection('devices')
          .doc(widget.deviceId)
          .collection('leaderboard')
          .where('showInLeaderboard', isEqualTo: true)
          .orderBy('level', descending: true)
          .orderBy('xp', descending: true)
          .get();

      final entries = await Future.wait(
        snap.docs.map((doc) async {
          final userDoc = await fs.collection('users').doc(doc.id).get();
          final userData = userDoc.data() ?? <String, dynamic>{};
          final role = userData['role'] as String?;
          if (role == 'admin') {
            return null;
          }
          final profile = PublicProfile.fromMap(doc.id, userData);
          final data = doc.data();
          final rawXp = (data['xp'] as num?)?.toInt() ?? 0;
          final rawLevel = (data['level'] as num?)?.toInt();

          int level;
          int xpInLevel;
          if (rawLevel == null || rawLevel < 1) {
            final resolved = _resolveLevelProgress(rawXp);
            level = resolved.level;
            xpInLevel = resolved.xpInLevel;
          } else {
            level = rawLevel.clamp(1, LevelService.maxLevel).toInt();
            final normalizedXp = rawXp < 0 ? 0 : rawXp;
            xpInLevel = level >= LevelService.maxLevel
                ? 0
                : normalizedXp % LevelService.xpPerLevel;
          }

          return _DeviceLeaderboardEntry(
            profile: profile,
            level: level,
            xpInLevel: xpInLevel,
          );
        }),
      );

      if (!mounted) return;
      setState(() {
        _entries = entries.whereType<_DeviceLeaderboardEntry>().toList();
      });
    } catch (error, stack) {
      debugPrint('Failed to load device leaderboard: $error');
      debugPrint('$stack');
      if (!mounted) return;
      setState(() {
        _entries = const [];
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
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

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final progressColor =
        brandTheme?.gradient.colors.first ?? theme.colorScheme.primary;
    final authView = ref.watch(authViewStateProvider);
    final currentUserId = authView.userId;

    final entries = _entries;

    Widget buildContent() {
      if (_loading && entries == null) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      if (entries == null || entries.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Center(
            child: Text(
              loc.leaderboardEmptyGym,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      }
      return _DeviceLevelLeaderboard(
        deviceName: widget.deviceName,
        entries: entries,
        progressColor: progressColor,
        selectedLevel: _selectedLevel,
        onLevelChanged: _updateSelectedLevel,
        currentUserId: currentUserId,
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          widget.deviceName,
          style: GoogleFonts.orbitron(
            textStyle: theme.textTheme.titleLarge,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.9,
          ),
        ),
      ),
      body: RankingGradientBackground(
        child: RefreshIndicator(
          color: progressColor,
          onRefresh: _loadEntries,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            children: [buildContent()],
          ),
        ),
      ),
    );
  }
}

class _DeviceLevelLeaderboard extends StatelessWidget {
  const _DeviceLevelLeaderboard({
    required this.deviceName,
    required this.entries,
    required this.progressColor,
    required this.selectedLevel,
    required this.onLevelChanged,
    this.currentUserId,
  });

  final String deviceName;
  final List<_DeviceLeaderboardEntry> entries;
  final Color progressColor;
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
      final bucket = levelEntries.putIfAbsent(entry.level, () => []);
      bucket.add(
        _LevelledEntry(profile: entry.profile, xpInLevel: entry.xpInLevel),
      );
    }

    final clampedSelectedLevel = selectedLevel.clamp(1, maxLevel).toInt();
    final currentLevelEntries =
        (levelEntries[clampedSelectedLevel] ?? const <_LevelledEntry>[])
            .toList()
          ..sort((a, b) {
            final xpCompare = b.xpInLevel.compareTo(a.xpInLevel);
            if (xpCompare != 0) return xpCompare;
            return a.profile.safeLower.compareTo(b.profile.safeLower);
          });

    int? selfRank;
    int? selfXpToNext;
    if (currentUserId != null && currentLevelEntries.isNotEmpty) {
      final selfIndex = currentLevelEntries.indexWhere(
        (entry) => entry.profile.uid == currentUserId,
      );
      if (selfIndex >= 0) {
        selfRank = selfIndex + 1;
        if (selfIndex > 0) {
          final xpAbove = currentLevelEntries[selfIndex - 1].xpInLevel;
          final xpSelf = currentLevelEntries[selfIndex].xpInLevel;
          selfXpToNext = (xpAbove - xpSelf).clamp(0, 1 << 31);
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DeviceLeaderboardHeroCard(
          deviceName: deviceName,
          selectedLevel: clampedSelectedLevel,
          rankInLevel: selfRank,
          xpToNextRank: selfXpToNext,
          userCountInLevel: currentLevelEntries.length,
          xpPerLevel: formatter.format(xpPerLevel),
          accent: progressColor,
        ),
        const SizedBox(height: AppSpacing.md),
        RankingNextRankSignalCard(
          accent: progressColor,
          rank: selfRank,
          xpToNextRank: selfXpToNext,
          participantCount: currentLevelEntries.length,
        ),
        const SizedBox(height: AppSpacing.md),
        RankingSurfacePanel(
          accent: progressColor,
          borderOpacity: 0.28,
          shadowOpacity: 0.36,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 42,
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
                      child: RankingSegmentChip(
                        label: 'Lvl $level',
                        selected: isSelected,
                        accent: progressColor,
                        onTap: () => onLevelChanged(level),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Level $clampedSelectedLevel Ranking',
                style: GoogleFonts.orbitron(
                  textStyle: theme.textTheme.labelLarge,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${formatter.format(xpPerLevel)} XP pro Level',
                style: GoogleFonts.rajdhani(
                  textStyle: theme.textTheme.bodySmall,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withOpacity(0.62),
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
                    style: GoogleFonts.rajdhani(
                      textStyle: theme.textTheme.bodyLarge,
                      color: theme.colorScheme.onSurface.withOpacity(0.66),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ] else ...[
                const SizedBox(height: AppSpacing.sm),
                ..._buildRows(
                  context: context,
                  entries: currentLevelEntries,
                  formatter: formatter,
                  xpPerLevel: xpPerLevel,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildRows({
    required BuildContext context,
    required List<_LevelledEntry> entries,
    required NumberFormat formatter,
    required int xpPerLevel,
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
                      color: progressColor.withOpacity(0.34),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [],
          ),
          child: FriendListTile(
            profile: entry.profile,
            subtitle: isCurrentUser ? '#$rank · Du' : '#$rank',
            trailing: SizedBox(
              width: 116,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${formatter.format(entry.xpInLevel)} XP',
                    style: GoogleFonts.rajdhani(
                      textStyle: theme.textTheme.bodyLarge,
                      fontWeight: FontWeight.w700,
                      color: isCurrentUser
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 6,
                      value: (entry.xpInLevel / xpPerLevel).clamp(0.0, 1.0),
                      backgroundColor: theme.colorScheme.onSurface.withOpacity(
                        0.12,
                      ),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isCurrentUser
                            ? theme.colorScheme.onPrimary
                            : progressColor,
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

    return widgets;
  }
}

class _DeviceLeaderboardEntry {
  final PublicProfile profile;
  final int level;
  final int xpInLevel;

  const _DeviceLeaderboardEntry({
    required this.profile,
    required this.level,
    required this.xpInLevel,
  });
}

class _LevelledEntry {
  final PublicProfile profile;
  final int xpInLevel;

  const _LevelledEntry({required this.profile, required this.xpInLevel});
}

class _LevelProgress {
  final int level;
  final int xpInLevel;

  const _LevelProgress({required this.level, required this.xpInLevel});
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
  return _LevelProgress(level: level, xpInLevel: xpInLevel);
}

class _DeviceLeaderboardHeroCard extends StatelessWidget {
  const _DeviceLeaderboardHeroCard({
    required this.deviceName,
    required this.selectedLevel,
    required this.rankInLevel,
    required this.xpToNextRank,
    required this.userCountInLevel,
    required this.xpPerLevel,
    required this.accent,
  });

  final String deviceName;
  final int selectedLevel;
  final int? rankInLevel;
  final int? xpToNextRank;
  final int userCountInLevel;
  final String xpPerLevel;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rankLabel = rankInLevel == null ? '-' : '#$rankInLevel';
    final gapLabel = xpToNextRank == null ? '-' : '$xpToNextRank XP';

    return RankingHeroCard(
      accent: accent,
      accentOpacity: 0.38,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            deviceName,
            style: GoogleFonts.orbitron(
              textStyle: theme.textTheme.titleLarge,
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Level $selectedLevel Ladder',
            style: GoogleFonts.rajdhani(
              textStyle: theme.textTheme.bodyLarge,
              color: Colors.white.withOpacity(0.82),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: RankingHeroStatTile(
                  label: 'Dein Rang',
                  value: rankLabel,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: RankingHeroStatTile(
                  label: 'Gap nach oben',
                  value: gapLabel,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: RankingHeroStatTile(
                  label: 'Aktive User',
                  value: '$userCountInLevel',
                  detail: '$xpPerLevel XP / Lvl',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

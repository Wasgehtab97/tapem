import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/features/friends/domain/models/public_profile.dart';
import 'package:tapem/features/friends/presentation/widgets/friend_list_tile.dart';
import 'package:tapem/features/rank/domain/services/level_service.dart';
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
          final xp = (doc.data()['xp'] as num?)?.toInt() ?? 0;
          return _DeviceLeaderboardEntry(profile: profile, xp: xp);
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
        entries: entries,
        progressColor: progressColor,
        title: widget.deviceName,
        selectedLevel: _selectedLevel,
        onLevelChanged: _updateSelectedLevel,
        currentUserId: currentUserId,
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.deviceName)),
      body: RefreshIndicator(
        onRefresh: _loadEntries,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.md,
          ),
          children: [
            buildContent(),
          ],
        ),
      ),
    );
  }
}

class _DeviceLevelLeaderboard extends StatelessWidget {
  const _DeviceLevelLeaderboard({
    required this.entries,
    required this.progressColor,
    required this.title,
    required this.selectedLevel,
    required this.onLevelChanged,
    this.currentUserId,
  });

  final List<_DeviceLeaderboardEntry> entries;
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
      final progress = _resolveLevelProgress(entry.xp);
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

    final clampedSelectedLevel =
        selectedLevel.clamp(1, maxLevel).toInt();
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
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
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
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
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

class _DeviceLeaderboardEntry {
  final PublicProfile profile;
  final int xp;

  const _DeviceLeaderboardEntry({
    required this.profile,
    required this.xp,
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

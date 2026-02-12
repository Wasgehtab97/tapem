import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:tapem/core/auth/role_utils.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/features/friends/domain/models/public_profile.dart';
import 'package:tapem/features/rank/presentation/widgets/ranking_ui.dart';
import 'package:tapem/l10n/app_localizations.dart';

class PowerliftingLeaderboardEntry {
  const PowerliftingLeaderboardEntry({
    required this.profile,
    required this.benchHeaviest,
    required this.benchE1rm,
    required this.squatHeaviest,
    required this.squatE1rm,
    required this.deadliftHeaviest,
    required this.deadliftE1rm,
  });

  final PublicProfile profile;
  final double benchHeaviest;
  final double benchE1rm;
  final double squatHeaviest;
  final double squatE1rm;
  final double deadliftHeaviest;
  final double deadliftE1rm;

  double get totalE1rm => benchE1rm + squatE1rm + deadliftE1rm;

  bool get hasAnyValue => benchE1rm > 0 || squatE1rm > 0 || deadliftE1rm > 0;
}

class PowerliftingLeaderboardScreen extends riverpod.ConsumerStatefulWidget {
  const PowerliftingLeaderboardScreen({super.key});

  @override
  riverpod.ConsumerState<PowerliftingLeaderboardScreen> createState() =>
      _PowerliftingLeaderboardScreenState();
}

class _PowerliftingLeaderboardScreenState
    extends riverpod.ConsumerState<PowerliftingLeaderboardScreen> {
  List<PowerliftingLeaderboardEntry>? _entries;
  PowerliftingLeaderboardEntry? _selfEntry;
  int? _selfRank;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refresh();
    });
  }

  Future<void> _refresh() async {
    final auth = ref.read(authControllerProvider);
    final gymId = auth.gymCode ?? '';
    final currentUserId = auth.userId;

    if (gymId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _entries = const [];
        _selfEntry = null;
        _selfRank = null;
        _error = null;
      });
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final fs = FirebaseFirestore.instance;
      final gymUsersSnap = await fs
          .collection('gyms')
          .doc(gymId)
          .collection('users')
          .get();

      final futures = gymUsersSnap.docs.map((userDoc) async {
        final uid = userDoc.id;
        final userSnap = await fs.collection('users').doc(uid).get();
        final userData = userSnap.data();
        if (userData == null) {
          return null;
        }

        final showInLeaderboard =
            userData['showInLeaderboard'] as bool? ?? true;
        final role = userData['role'] as String?;
        if (!showInLeaderboard || isAdminLikeRole(role)) {
          return null;
        }

        final profile = PublicProfile.fromMap(uid, userData);

        final statsSnap = await fs
            .collection('gyms')
            .doc(gymId)
            .collection('users')
            .doc(uid)
            .collection('rank')
            .doc('powerlifting')
            .get();
        final stats = statsSnap.data();
        if (stats == null) {
          return null;
        }

        double readDouble(String key) => (stats[key] as num?)?.toDouble() ?? 0;

        final entry = PowerliftingLeaderboardEntry(
          profile: profile,
          benchHeaviest: readDouble('benchHeaviestKg'),
          benchE1rm: readDouble('benchE1rmKg'),
          squatHeaviest: readDouble('squatHeaviestKg'),
          squatE1rm: readDouble('squatE1rmKg'),
          deadliftHeaviest: readDouble('deadliftHeaviestKg'),
          deadliftE1rm: readDouble('deadliftE1rmKg'),
        );

        if (!entry.hasAnyValue) {
          return null;
        }
        return entry;
      }).toList();

      final allEntries =
          (await Future.wait(
            futures,
          )).whereType<PowerliftingLeaderboardEntry>().toList()..sort((a, b) {
            final totalCompare = b.totalE1rm.compareTo(a.totalE1rm);
            if (totalCompare != 0) return totalCompare;
            return a.profile.safeLower.compareTo(b.profile.safeLower);
          });

      PowerliftingLeaderboardEntry? selfEntry;
      int? selfRank;
      if (currentUserId != null) {
        final selfIndex = allEntries.indexWhere(
          (entry) => entry.profile.uid == currentUserId,
        );
        if (selfIndex >= 0) {
          selfEntry = allEntries[selfIndex];
          selfRank = selfIndex + 1;
        }
      }

      if (!mounted) return;
      setState(() {
        _entries = allEntries;
        _selfEntry = selfEntry;
        _selfRank = selfRank;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _entries = const [];
        _selfEntry = null;
        _selfRank = null;
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final accentColor = brandTheme?.outline ?? theme.colorScheme.secondary;
    final entries = _entries;
    final locale = Localizations.localeOf(context).toString();
    final decimalFormatter = NumberFormat.decimalPattern(locale);
    final oneDecimalFormatter = NumberFormat.decimalPatternDigits(
      locale: locale,
      decimalDigits: 1,
    );

    Widget bodyContent() {
      if (_isLoading && entries == null) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Center(child: CircularProgressIndicator()),
        );
      }

      if (_error != null) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Center(
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        );
      }

      if (entries == null || entries.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Center(
            child: Text(
              loc.leaderboardEmptyGym,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
        );
      }

      final topEntries = entries.take(10).toList();
      final topEntry = entries.first;
      final selfEntry = _selfEntry;
      final selfRank = _selfRank;
      double? kgGapToNext;
      if (selfEntry != null && selfRank != null && selfRank > 1) {
        final previousEntry = entries[selfRank - 2];
        kgGapToNext = math.max(
          0,
          previousEntry.totalE1rm - selfEntry.totalE1rm,
        );
      }

      return Column(
        children: [
          _PowerliftingHeroCard(
            title: loc.powerliftingTitle,
            selfRank: selfRank,
            selfTotal: selfEntry?.totalE1rm,
            topTotal: topEntry.totalE1rm,
            kgGapToNext: kgGapToNext,
            formatter: decimalFormatter,
            oneDecimalFormatter: oneDecimalFormatter,
            accent: accentColor,
          ),
          const SizedBox(height: AppSpacing.md),
          _PowerliftingPodium(
            entries: topEntries.take(3).toList(),
            formatter: decimalFormatter,
            oneDecimalFormatter: oneDecimalFormatter,
          ),
          const SizedBox(height: AppSpacing.md),
          _PowerliftingLeaderboardPanel(
            entries: topEntries,
            currentUserId: _selfEntry?.profile.uid,
            formatter: decimalFormatter,
            oneDecimalFormatter: oneDecimalFormatter,
            accent: accentColor,
          ),
          if (selfEntry != null &&
              !topEntries.any(
                (entry) => entry.profile.uid == selfEntry.profile.uid,
              )) ...[
            const SizedBox(height: AppSpacing.md),
            _PowerliftingSelfCard(
              rank: selfRank ?? 0,
              entry: selfEntry,
              formatter: decimalFormatter,
              oneDecimalFormatter: oneDecimalFormatter,
              accentColor: accentColor,
            ),
          ],
        ],
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          loc.powerliftingTitle,
          style: GoogleFonts.orbitron(
            textStyle: theme.textTheme.titleLarge,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ),
      body: RankingGradientBackground(
        child: RefreshIndicator(
          color: accentColor,
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [bodyContent()],
          ),
        ),
      ),
    );
  }
}

class _PowerliftingHeroCard extends StatelessWidget {
  const _PowerliftingHeroCard({
    required this.title,
    required this.selfRank,
    required this.selfTotal,
    required this.topTotal,
    required this.kgGapToNext,
    required this.formatter,
    required this.oneDecimalFormatter,
    required this.accent,
  });

  final String title;
  final int? selfRank;
  final double? selfTotal;
  final double topTotal;
  final double? kgGapToNext;
  final NumberFormat formatter;
  final NumberFormat oneDecimalFormatter;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rankLabel = selfRank == null ? '-' : '#$selfRank';
    final totalLabel = selfTotal == null
        ? '-'
        : _formatWeight(selfTotal!, oneDecimalFormatter);
    final gapLabel = kgGapToNext == null
        ? '-'
        : _formatWeight(kgGapToNext!, oneDecimalFormatter);
    final leaderLabel = _formatWeight(topTotal, oneDecimalFormatter);

    return RankingHeroCard(
      accent: accent,
      accentOpacity: 0.34,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.orbitron(
              textStyle: theme.textTheme.titleLarge,
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Top 10 deines Gyms mit Bench, Squat, Deadlift und Total E1RM.',
            style: GoogleFonts.rajdhani(
              textStyle: theme.textTheme.bodyLarge,
              color: Colors.white.withOpacity(0.84),
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
                  label: 'Dein Total',
                  value: totalLabel,
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
                  label: 'Gym-Bestwert',
                  value: leaderLabel,
                  detail: '${formatter.format(topTotal.round())} kg',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PowerliftingPodium extends StatelessWidget {
  const _PowerliftingPodium({
    required this.entries,
    required this.formatter,
    required this.oneDecimalFormatter,
  });

  final List<PowerliftingLeaderboardEntry> entries;
  final NumberFormat formatter;
  final NumberFormat oneDecimalFormatter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }

    return RankingSurfacePanel(
      accent: theme.colorScheme.onSurface,
      borderOpacity: 0.08,
      shadowOpacity: 0,
      child: Row(
        children: List.generate(entries.length, (index) {
          final rank = index + 1;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: rank == entries.length ? 0 : AppSpacing.xs,
              ),
              child: _PodiumCard(
                rank: rank,
                entry: entries[index],
                formatter: formatter,
                oneDecimalFormatter: oneDecimalFormatter,
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _PodiumCard extends StatelessWidget {
  const _PodiumCard({
    required this.rank,
    required this.entry,
    required this.formatter,
    required this.oneDecimalFormatter,
  });

  final int rank;
  final PowerliftingLeaderboardEntry entry;
  final NumberFormat formatter;
  final NumberFormat oneDecimalFormatter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final medal = switch (rank) {
      1 => '1',
      2 => '2',
      3 => '3',
      _ => '$rank',
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.surface.withOpacity(0.98),
            theme.colorScheme.surface.withOpacity(0.88),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '#$medal',
            style: GoogleFonts.orbitron(
              textStyle: theme.textTheme.labelLarge,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            entry.profile.username,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.rajdhani(
              textStyle: theme.textTheme.titleSmall,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _formatWeight(entry.totalE1rm, oneDecimalFormatter),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.orbitron(
              textStyle: theme.textTheme.bodyLarge,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${formatter.format(entry.totalE1rm.round())} kg total',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.rajdhani(
              textStyle: theme.textTheme.labelSmall,
              color: theme.colorScheme.onSurface.withOpacity(0.66),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PowerliftingLeaderboardPanel extends StatelessWidget {
  const _PowerliftingLeaderboardPanel({
    required this.entries,
    required this.currentUserId,
    required this.formatter,
    required this.oneDecimalFormatter,
    required this.accent,
  });

  final List<PowerliftingLeaderboardEntry> entries;
  final String? currentUserId;
  final NumberFormat formatter;
  final NumberFormat oneDecimalFormatter;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return RankingSurfacePanel(
      accent: accent,
      borderOpacity: 0.28,
      shadowOpacity: 0.36,
      child: Column(
        children: [
          const _LeaderboardHeader(),
          const SizedBox(height: AppSpacing.xs),
          ...List.generate(entries.length, (index) {
            final entry = entries[index];
            final isSelf =
                currentUserId != null && currentUserId == entry.profile.uid;
            return Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs / 2),
              child: _LeaderboardRow(
                rank: index + 1,
                entry: entry,
                isSelf: isSelf,
                oneDecimalFormatter: oneDecimalFormatter,
                formatter: formatter,
                accent: accent,
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _LeaderboardHeader extends StatelessWidget {
  const _LeaderboardHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(
              '#',
              style: GoogleFonts.orbitron(
                textStyle: theme.textTheme.labelMedium,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              'Athlet',
              style: GoogleFonts.orbitron(
                textStyle: theme.textTheme.labelMedium,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              'B / S / D (E1RM)',
              textAlign: TextAlign.end,
              style: GoogleFonts.orbitron(
                textStyle: theme.textTheme.labelMedium,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 3,
            child: Text(
              'Total',
              textAlign: TextAlign.end,
              style: GoogleFonts.orbitron(
                textStyle: theme.textTheme.labelMedium,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({
    required this.rank,
    required this.entry,
    required this.isSelf,
    required this.oneDecimalFormatter,
    required this.formatter,
    required this.accent,
  });

  final int rank;
  final PowerliftingLeaderboardEntry entry;
  final bool isSelf;
  final NumberFormat oneDecimalFormatter;
  final NumberFormat formatter;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rowAccent = isSelf ? accent : theme.colorScheme.onSurface;
    final b = _formatCompact(entry.benchE1rm, oneDecimalFormatter);
    final s = _formatCompact(entry.squatE1rm, oneDecimalFormatter);
    final d = _formatCompact(entry.deadliftE1rm, oneDecimalFormatter);
    final total = _formatCompact(entry.totalE1rm, oneDecimalFormatter);

    return Container(
      decoration: BoxDecoration(
        gradient: isSelf
            ? LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [accent.withOpacity(0.34), accent.withOpacity(0.08)],
              )
            : null,
        color: isSelf ? null : theme.colorScheme.onSurface.withOpacity(0.02),
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(
          color: isSelf
              ? accent.withOpacity(0.78)
              : theme.colorScheme.onSurface.withOpacity(0.08),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(
              '#$rank',
              style: GoogleFonts.orbitron(
                textStyle: theme.textTheme.labelLarge,
                fontWeight: FontWeight.w700,
                color: rowAccent,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              entry.profile.username,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.rajdhani(
                textStyle: theme.textTheme.titleSmall,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              '$b / $s / $d',
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.rajdhani(
                textStyle: theme.textTheme.bodyMedium,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withOpacity(0.76),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 3,
            child: Text(
              total,
              textAlign: TextAlign.end,
              style: GoogleFonts.orbitron(
                textStyle: theme.textTheme.bodyMedium,
                fontWeight: FontWeight.w700,
                color: isSelf ? accent : theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PowerliftingSelfCard extends StatelessWidget {
  const _PowerliftingSelfCard({
    required this.rank,
    required this.entry,
    required this.formatter,
    required this.oneDecimalFormatter,
    required this.accentColor,
  });

  final int rank;
  final PowerliftingLeaderboardEntry entry;
  final NumberFormat formatter;
  final NumberFormat oneDecimalFormatter;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            accentColor.withOpacity(0.42),
            accentColor.withOpacity(0.12),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: accentColor.withOpacity(0.62)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Deine Position ausserhalb der Top 10: #$rank',
            style: GoogleFonts.orbitron(
              textStyle: theme.textTheme.labelLarge,
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            entry.profile.username,
            style: GoogleFonts.rajdhani(
              textStyle: theme.textTheme.titleLarge,
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              _MetricChip(
                label: 'Bench',
                value: _formatWeight(entry.benchE1rm, oneDecimalFormatter),
              ),
              _MetricChip(
                label: 'Squat',
                value: _formatWeight(entry.squatE1rm, oneDecimalFormatter),
              ),
              _MetricChip(
                label: 'Deadlift',
                value: _formatWeight(entry.deadliftE1rm, oneDecimalFormatter),
              ),
              _MetricChip(
                label: 'Total',
                value: _formatWeight(entry.totalE1rm, oneDecimalFormatter),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${formatter.format(entry.totalE1rm.round())} kg Total E1RM',
            style: GoogleFonts.rajdhani(
              textStyle: theme.textTheme.bodyMedium,
              color: Colors.white.withOpacity(0.85),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.32),
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.rajdhani(
              textStyle: theme.textTheme.labelSmall,
              color: Colors.white.withOpacity(0.82),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: GoogleFonts.orbitron(
              textStyle: theme.textTheme.labelMedium,
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatWeight(double value, NumberFormat formatter) {
  if (value <= 0) return '-';
  return '${formatter.format(value)} kg';
}

String _formatCompact(double value, NumberFormat formatter) {
  if (value <= 0) return '-';
  return formatter.format(value);
}

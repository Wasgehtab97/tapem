import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;

import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/features/friends/domain/models/public_profile.dart';
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

  bool get hasAnyValue =>
      benchE1rm > 0 || squatE1rm > 0 || deadliftE1rm > 0;
}

class PowerliftingLeaderboardScreen extends StatefulWidget {
  const PowerliftingLeaderboardScreen({super.key});

  @override
  State<PowerliftingLeaderboardScreen> createState() =>
      _PowerliftingLeaderboardScreenState();
}

class _PowerliftingLeaderboardScreenState
    extends State<PowerliftingLeaderboardScreen> {
  List<PowerliftingLeaderboardEntry>? _entries;
  PowerliftingLeaderboardEntry? _selfEntry;
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
    final auth = riverpod.ProviderScope.containerOf(context, listen: false)
        .read(authControllerProvider);
    final gymId = auth.gymCode ?? '';
    final currentUserId = auth.userId;

    if (gymId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _entries = const [];
        _selfEntry = null;
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
      final gymUsersSnap =
          await fs.collection('gyms').doc(gymId).collection('users').get();

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
        if (!showInLeaderboard || role == 'admin') {
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

        double readDouble(String key) =>
            (stats[key] as num?)?.toDouble() ?? 0;

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

      final allEntries = (await Future.wait(futures))
          .whereType<PowerliftingLeaderboardEntry>()
          .toList()
        ..sort((a, b) => b.totalE1rm.compareTo(a.totalE1rm));

      final topEntries =
          allEntries.length > 10 ? allEntries.sublist(0, 10) : allEntries;
      final selfEntry = currentUserId == null
          ? null
          : allEntries.firstWhere(
              (e) => e.profile.uid == currentUserId,
              orElse: () => const PowerliftingLeaderboardEntry(
                profile: PublicProfile(
                  uid: '',
                  username: '',
                ),
                benchHeaviest: 0,
                benchE1rm: 0,
                squatHeaviest: 0,
                squatE1rm: 0,
                deadliftHeaviest: 0,
                deadliftE1rm: 0,
              ),
            );

      if (!mounted) return;

      setState(() {
        _entries = topEntries;
        _selfEntry =
            selfEntry != null && selfEntry.profile.uid.isNotEmpty
                ? selfEntry
                : null;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _entries = const [];
        _selfEntry = null;
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

    Widget buildBody() {
      final children = <Widget>[];

      if (_isLoading && (entries == null || entries.isEmpty)) {
        children.addAll([
          const SizedBox(height: AppSpacing.lg),
          const Center(child: CircularProgressIndicator()),
        ]);
      } else if (_error != null) {
        children.addAll([
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        ]);
      } else if (entries == null || entries.isEmpty) {
        children.addAll([
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: Text(
              loc.leaderboardEmptyGym,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
        ]);
      } else {
        children.addAll([
          Text(
            loc.powerliftingTitle,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Top 10 deines Studios – Bench, Squat und Deadlift auf einen Blick.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _PowerliftingLeaderboardTable(
            entries: entries,
            accentColor: accentColor,
          ),
          if (_selfEntry != null &&
              !_entries!
                  .any((e) => e.profile.uid == _selfEntry!.profile.uid)) ...[
            const SizedBox(height: AppSpacing.lg),
            _PowerliftingSelfCard(
              entry: _selfEntry!,
              accentColor: accentColor,
            ),
          ],
        ]);
      }

      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        children: children,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.powerliftingTitle),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: buildBody(),
      ),
    );
  }
}

class _PowerliftingLeaderboardTable extends StatelessWidget {
  const _PowerliftingLeaderboardTable({
    required this.entries,
    required this.accentColor,
  });

  final List<PowerliftingLeaderboardEntry> entries;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final gradient = brandTheme?.gradient ?? AppGradients.brandGradient;

    final headerStyle = theme.textTheme.labelSmall?.copyWith(
      color: Colors.white.withOpacity(0.9),
      fontWeight: FontWeight.w600,
      letterSpacing: 0.6,
    );
    final cellStyle = theme.textTheme.bodyMedium?.copyWith(
      color: Colors.white.withOpacity(0.95),
      fontWeight: FontWeight.w500,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(1.5),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Container(
            color: const Color(0xFF050608),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 40,
                dataRowHeight: 60,
                columnSpacing: 28,
                headingRowColor: MaterialStateProperty.all(
                  const Color(0xFF111217),
                ),
                dataRowColor: MaterialStateProperty.resolveWith((states) {
                  if (states.contains(MaterialState.selected)) {
                    return accentColor.withOpacity(0.24);
                  }
                  return Colors.white.withOpacity(0.02);
                }),
                columns: [
                  DataColumn(
                    label: Text('# / User', style: headerStyle),
                  ),
                  DataColumn(
                    label: Text('BD max', style: headerStyle),
                  ),
                  DataColumn(
                    label: Text('BD E1RM', style: headerStyle),
                  ),
                  DataColumn(
                    label: Text('KB max', style: headerStyle),
                  ),
                  DataColumn(
                    label: Text('KB E1RM', style: headerStyle),
                  ),
                  DataColumn(
                    label: Text('KH max', style: headerStyle),
                  ),
                  DataColumn(
                    label: Text('KH E1RM', style: headerStyle),
                  ),
                ],
                rows: [
                  for (var i = 0; i < entries.length; i++)
                    _buildRow(
                      context: context,
                      index: i,
                      entry: entries[i],
                      cellStyle: cellStyle,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  DataRow _buildRow({
    required BuildContext context,
    required int index,
    required PowerliftingLeaderboardEntry entry,
    required TextStyle? cellStyle,
  }) {
    final theme = Theme.of(context);
    final rank = index + 1;
    final isTopThree = rank <= 3;
    final rankColor = isTopThree ? accentColor : theme.colorScheme.onSurface;

    String rankLabel;
    switch (rank) {
      case 1:
        rankLabel = '🥇 1';
        break;
      case 2:
        rankLabel = '🥈 2';
        break;
      case 3:
        rankLabel = '🥉 3';
        break;
      default:
        rankLabel = '#$rank';
    }

    String formatWeight(double value) {
      if (value <= 0) return '-';
      return value % 1 == 0
          ? '${value.toStringAsFixed(0)} kg'
          : '${value.toStringAsFixed(1)} kg';
    }

    return DataRow(
      cells: [
        DataCell(
          Row(
            children: [
              Text(
                rankLabel,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: rankColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  entry.profile.username,
                  overflow: TextOverflow.ellipsis,
                  style: cellStyle,
                ),
              ),
            ],
          ),
        ),
        DataCell(Text(formatWeight(entry.benchHeaviest), style: cellStyle)),
        DataCell(Text(formatWeight(entry.benchE1rm), style: cellStyle)),
        DataCell(Text(formatWeight(entry.squatHeaviest), style: cellStyle)),
        DataCell(Text(formatWeight(entry.squatE1rm), style: cellStyle)),
        DataCell(Text(formatWeight(entry.deadliftHeaviest), style: cellStyle)),
        DataCell(Text(formatWeight(entry.deadliftE1rm), style: cellStyle)),
      ],
    );
  }
}

class _PowerliftingSelfCard extends StatelessWidget {
  const _PowerliftingSelfCard({
    required this.entry,
    required this.accentColor,
  });

  final PowerliftingLeaderboardEntry entry;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String formatWeight(double value) {
      if (value <= 0) return '-';
      return value % 1 == 0
          ? '${value.toStringAsFixed(0)} kg'
          : '${value.toStringAsFixed(1)} kg';
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            accentColor.withOpacity(0.4),
            accentColor.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.36),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Deine Powerlifting-Leistung',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            entry.profile.username,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: [
              _metricChip(
                context,
                label: 'Bankdrücken max',
                value: formatWeight(entry.benchHeaviest),
              ),
              _metricChip(
                context,
                label: 'Bankdrücken E1RM',
                value: formatWeight(entry.benchE1rm),
              ),
              _metricChip(
                context,
                label: 'Kniebeugen max',
                value: formatWeight(entry.squatHeaviest),
              ),
              _metricChip(
                context,
                label: 'Kniebeugen E1RM',
                value: formatWeight(entry.squatE1rm),
              ),
              _metricChip(
                context,
                label: 'Kreuzheben max',
                value: formatWeight(entry.deadliftHeaviest),
              ),
              _metricChip(
                context,
                label: 'Kreuzheben E1RM',
                value: formatWeight(entry.deadliftE1rm),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricChip(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(
          color: Colors.white.withOpacity(0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

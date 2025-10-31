import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/machine_attempt_repository_impl.dart';
import '../../domain/models/leaderboard_entry.dart';
import '../../domain/services/leaderboard_service.dart';
import '../../domain/utils/leaderboard_time_utils.dart';
import '../models/device_leaderboard_state.dart';
import 'package:tapem/l10n/app_localizations.dart';

class MachineLeaderboardSheet extends StatelessWidget {
  final String gymId;
  final String machineId;
  final bool isMulti;
  final String title;
  final LeaderboardService? serviceOverride;

  const MachineLeaderboardSheet({
    super.key,
    required this.gymId,
    required this.machineId,
    required this.isMulti,
    required this.title,
    this.serviceOverride,
  });

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.8,
      child: ChangeNotifierProvider(
        create: (_) => DeviceLeaderboardNotifier(
          service: serviceOverride ??
              LeaderboardService(
                repository: MachineAttemptRepositoryImpl(),
              ),
          gymId: gymId,
          machineId: machineId,
          isMulti: isMulti,
        )..ensureLoaded(),
        child: _MachineLeaderboardContent(title: title, isMulti: isMulti),
      ),
    );
  }
}

class _MachineLeaderboardContent extends StatelessWidget {
  final String title;
  final bool isMulti;

  const _MachineLeaderboardContent({
    required this.title,
    required this.isMulti,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    return DefaultTabController(
      length: 3,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Container(
                width: 48,
                height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              loc.deviceLeaderboardTitle(title),
              style: textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (isMulti)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  loc.deviceLeaderboardUnavailable,
                  style: textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              )
            else ...[
              _LeaderboardTabs(onTabChanged: (index) {
                final notifier = context.read<DeviceLeaderboardNotifier>();
                final period = LeaderboardPeriod.values[index];
                notifier.setPeriod(period);
              }),
              const SizedBox(height: 12),
              const _LeaderboardFilters(),
              const SizedBox(height: 12),
              Expanded(
                child: TabBarView(
                  children: [
                    _LeaderboardTab(period: LeaderboardPeriod.today),
                    _LeaderboardTab(period: LeaderboardPeriod.week),
                    _LeaderboardTab(period: LeaderboardPeriod.month),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeaderboardTabs extends StatelessWidget {
  final ValueChanged<int> onTabChanged;

  const _LeaderboardTabs({required this.onTabChanged});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Consumer<DeviceLeaderboardNotifier>(
      builder: (context, notifier, _) {
        return TabBar(
          onTap: onTabChanged,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.textTheme.bodyMedium?.color,
          tabs: [
            Tab(text: loc.deviceLeaderboardTabToday),
            Tab(text: loc.deviceLeaderboardTabWeek),
            Tab(text: loc.deviceLeaderboardTabMonth),
          ],
        );
      },
    );
  }
}

class _LeaderboardFilters extends StatelessWidget {
  const _LeaderboardFilters();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Consumer<DeviceLeaderboardNotifier>(
      builder: (context, notifier, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _FilterChip(
                  label: loc.deviceLeaderboardFilterAll,
                  selected: notifier.genderFilter == LeaderboardGenderFilter.all,
                  onSelected: (_) =>
                      notifier.setGenderFilter(LeaderboardGenderFilter.all),
                ),
                _FilterChip(
                  label: loc.deviceLeaderboardFilterFemale,
                  selected:
                      notifier.genderFilter == LeaderboardGenderFilter.female,
                  onSelected: (_) =>
                      notifier.setGenderFilter(LeaderboardGenderFilter.female),
                ),
                _FilterChip(
                  label: loc.deviceLeaderboardFilterMale,
                  selected: notifier.genderFilter == LeaderboardGenderFilter.male,
                  onSelected: (_) =>
                      notifier.setGenderFilter(LeaderboardGenderFilter.male),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _FilterChip(
                  label: loc.deviceLeaderboardFilterAbsolute,
                  selected:
                      notifier.scoreMode == LeaderboardScoreMode.absolute,
                  onSelected: (_) =>
                      notifier.setScoreMode(LeaderboardScoreMode.absolute),
                ),
                _FilterChip(
                  label: loc.deviceLeaderboardFilterRelative,
                  selected:
                      notifier.scoreMode == LeaderboardScoreMode.relative,
                  onSelected: (_) =>
                      notifier.setScoreMode(LeaderboardScoreMode.relative),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
    );
  }
}

class _LeaderboardTab extends StatelessWidget {
  final LeaderboardPeriod period;

  const _LeaderboardTab({required this.period});

  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceLeaderboardNotifier>(
      builder: (context, notifier, _) {
        final loc = AppLocalizations.of(context)!;
        final state = notifier.stateFor(period);
        switch (state.status) {
          case DeviceLeaderboardStatus.initial:
            notifier.ensureLoaded(period);
            return const Center(child: CircularProgressIndicator());
          case DeviceLeaderboardStatus.loading:
            return const Center(child: CircularProgressIndicator());
          case DeviceLeaderboardStatus.error:
            return Center(
              child: Text(
                loc.deviceLeaderboardError,
                textAlign: TextAlign.center,
              ),
            );
          case DeviceLeaderboardStatus.empty:
            return Center(
              child: Text(
                loc.deviceLeaderboardEmpty,
                textAlign: TextAlign.center,
              ),
            );
          case DeviceLeaderboardStatus.loaded:
            return _LeaderboardEntries(entries: state.entries);
        }
      },
    );
  }
}

class _LeaderboardEntries extends StatelessWidget {
  final List<LeaderboardEntry> entries;

  const _LeaderboardEntries({required this.entries});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final numberFormat = NumberFormat('###0.0');
    final dateFormat = DateFormat.yMd().add_Hm();

    final items = entries.asMap().entries.toList();
    return ListView(
      children: [
        for (final item in items)
          if (item.key == 0)
            Card(
              color: theme.colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _LeaderboardEntryTile(
                  entry: item.value,
                  numberFormat: numberFormat,
                  dateFormat: dateFormat,
                  highlight: true,
                  loc: loc,
                  rank: item.key + 1,
                ),
              ),
            )
          else
            ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.secondaryContainer,
                child: Text('${item.key + 1}'),
              ),
              title: _LeaderboardEntryTitle(
                entry: item.value,
                numberFormat: numberFormat,
                loc: loc,
              ),
              subtitle: _LeaderboardEntrySubtitle(
                entry: item.value,
                dateFormat: dateFormat,
                loc: loc,
              ),
            ),
      ],
    );
  }
}

class _LeaderboardEntryTile extends StatelessWidget {
  final LeaderboardEntry entry;
  final NumberFormat numberFormat;
  final DateFormat dateFormat;
  final bool highlight;
  final AppLocalizations loc;
  final int rank;

  const _LeaderboardEntryTile({
    required this.entry,
    required this.numberFormat,
    required this.dateFormat,
    required this.highlight,
    required this.loc,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (highlight)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(
                  Icons.emoji_events,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            if (!highlight)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: CircleAvatar(
                  backgroundColor: theme.colorScheme.secondaryContainer,
                  child: Text('$rank'),
                ),
              ),
            Expanded(
              child: _LeaderboardEntryTitle(
                entry: entry,
                numberFormat: numberFormat,
                loc: loc,
              ),
            ),
            Text(
              _formatPrimaryScore(entry, numberFormat, loc),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _LeaderboardEntrySubtitle(
          entry: entry,
          dateFormat: dateFormat,
          loc: loc,
        ),
      ],
    );
  }
}

class _LeaderboardEntryTitle extends StatelessWidget {
  final LeaderboardEntry entry;
  final NumberFormat numberFormat;
  final AppLocalizations loc;

  const _LeaderboardEntryTitle({
    required this.entry,
    required this.numberFormat,
    required this.loc,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          entry.attempt.username,
          style: textTheme.titleMedium,
        ),
        Text(
          '${numberFormat.format(entry.attempt.e1rm)} kg',
          style: textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _LeaderboardEntrySubtitle extends StatelessWidget {
  final LeaderboardEntry entry;
  final DateFormat dateFormat;
  final AppLocalizations loc;

  const _LeaderboardEntrySubtitle({
    required this.entry,
    required this.dateFormat,
    required this.loc,
  });

  @override
  Widget build(BuildContext context) {
    final details = <String>[];
    final reps = entry.attempt.reps;
    final weight = entry.attempt.weight;
    if (weight != null && reps != null) {
      details.add('${weight.toStringAsFixed(1)} kg × $reps');
    }
    final relative = entry.mode == LeaderboardScoreMode.relative
        ? entry.score.toStringAsFixed(2)
        : null;
    if (relative != null) {
      details.add(loc.deviceLeaderboardRelativeValue(relative));
    }
    details.add(dateFormat.format(entry.attempt.createdAt.toLocal()));

    return Text(details.join(' • '));
  }
}

String _formatPrimaryScore(
  LeaderboardEntry entry,
  NumberFormat numberFormat,
  AppLocalizations loc,
) {
  if (entry.mode == LeaderboardScoreMode.absolute) {
    return '${numberFormat.format(entry.score)} kg';
  }
  final ratio = entry.score;
  return loc.deviceLeaderboardRelativeScore(ratio.toStringAsFixed(2));
}

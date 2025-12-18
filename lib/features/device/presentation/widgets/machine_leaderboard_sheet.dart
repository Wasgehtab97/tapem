import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tapem/l10n/app_localizations.dart';

import '../../data/repositories/machine_attempt_repository_impl.dart';
import '../../domain/models/leaderboard_entry.dart';
import '../../domain/services/leaderboard_service.dart';
import '../../domain/utils/leaderboard_time_utils.dart';
import '../models/device_leaderboard_state.dart';

class MachineLeaderboardSheet extends StatefulWidget {
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
  State<MachineLeaderboardSheet> createState() =>
      _MachineLeaderboardSheetState();
}

class _MachineLeaderboardSheetState extends State<MachineLeaderboardSheet> {
  late final DeviceLeaderboardNotifier _notifier;

  @override
  void initState() {
    super.initState();
    _notifier = DeviceLeaderboardNotifier(
      service: widget.serviceOverride ??
          LeaderboardService(
            repository: MachineAttemptRepositoryImpl(),
          ),
      gymId: widget.gymId,
      machineId: widget.machineId,
      isMulti: widget.isMulti,
      initialGenderFilter: LeaderboardGenderFilter.all,
    )..ensureLoaded();
  }

  @override
  void dispose() {
    _notifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.85,
      child: AnimatedBuilder(
        animation: _notifier,
        builder: (context, _) => _MachineLeaderboardContent(
          title: widget.title,
          isMulti: widget.isMulti,
          notifier: _notifier,
        ),
      ),
    );
  }
}

class _MachineLeaderboardContent extends StatelessWidget {
  final String title;
  final bool isMulti;
  final DeviceLeaderboardNotifier notifier;

  const _MachineLeaderboardContent({
    required this.title,
    required this.isMulti,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return DefaultTabController(
      length: 3,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.colorScheme.surfaceVariant.withOpacity(0.95),
                theme.colorScheme.surface,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: 56,
                      height: 6,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Builder(builder: (context) {
                    final resolvedTitle = _resolveLeaderboardTitle(
                      loc,
                      title,
                      notifier.genderFilter,
                    );
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: Text(
                        resolvedTitle,
                        key: ValueKey(resolvedTitle),
                        style: textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ) ??
                            TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.onSurface,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                  if (isMulti)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 48,
                              color: theme.colorScheme.secondary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              loc.deviceLeaderboardUnavailable,
                              style: textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    _LeaderboardTabs(
                      onTabChanged: (index) {
                        final period = LeaderboardPeriod.values[index];
                        notifier.setPeriod(period);
                      },
                    ),
                    const SizedBox(height: 18),
                    _LeaderboardFilters(notifier: notifier),
                    const SizedBox(height: 20),
                    Expanded(
                      child: TabBarView(
                        physics: const BouncingScrollPhysics(),
                        children: const [
                          _LeaderboardTab(period: LeaderboardPeriod.today),
                          _LeaderboardTab(period: LeaderboardPeriod.week),
                          _LeaderboardTab(period: LeaderboardPeriod.month),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
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
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.75),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.08),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: TabBar(
        onTap: onTabChanged,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: theme.colorScheme.primary.withOpacity(0.16),
        ),
        labelColor: theme.colorScheme.primary,
        unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
        labelStyle: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
        tabs: [
          Tab(text: loc.deviceLeaderboardTabToday),
          Tab(text: loc.deviceLeaderboardTabWeek),
          Tab(text: loc.deviceLeaderboardTabMonth),
        ],
      ),
    );
  }
}

class _LeaderboardFilters extends StatelessWidget {
  final DeviceLeaderboardNotifier notifier;

  const _LeaderboardFilters({required this.notifier});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withOpacity(0.78),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.08),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.deviceLeaderboardFilterGenderLabel,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _FilterChip(
                    label: loc.deviceLeaderboardFilterAll,
                    icon: Icons.all_inclusive_rounded,
                    selected: notifier.genderFilter == LeaderboardGenderFilter.all,
                    onSelected: (_) =>
                        notifier.setGenderFilter(LeaderboardGenderFilter.all),
                  ),
                  _FilterChip(
                    label: loc.deviceLeaderboardFilterFemale,
                    icon: Icons.female_rounded,
                    selected:
                        notifier.genderFilter == LeaderboardGenderFilter.female,
                    onSelected: (_) =>
                        notifier.setGenderFilter(LeaderboardGenderFilter.female),
                  ),
                  _FilterChip(
                    label: loc.deviceLeaderboardFilterMale,
                    icon: Icons.male_rounded,
                    selected: notifier.genderFilter == LeaderboardGenderFilter.male,
                    onSelected: (_) =>
                        notifier.setGenderFilter(LeaderboardGenderFilter.male),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                loc.deviceLeaderboardFilterScoreLabel,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _FilterChip(
                    label: loc.deviceLeaderboardFilterAbsolute,
                    icon: Icons.fitness_center_rounded,
                    selected:
                        notifier.scoreMode == LeaderboardScoreMode.absolute,
                    onSelected: (_) =>
                        notifier.setScoreMode(LeaderboardScoreMode.absolute),
                  ),
                  _FilterChip(
                    label: loc.deviceLeaderboardFilterRelative,
                    icon: Icons.scale_rounded,
                    selected:
                        notifier.scoreMode == LeaderboardScoreMode.relative,
                    onSelected: (_) =>
                        notifier.setScoreMode(LeaderboardScoreMode.relative),
                  ),
                ],
              ),
            ],
          ),
        );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final IconData? icon;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    final background = selected
        ? theme.colorScheme.primary.withOpacity(0.18)
        : theme.colorScheme.surfaceVariant.withOpacity(0.5);

    return ChoiceChip(
      avatar: icon != null
          ? Icon(
              icon,
              size: 18,
              color: foreground,
            )
          : null,
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      pressElevation: 0,
      labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: foreground,
            fontWeight: FontWeight.w700,
          ),
      backgroundColor: background,
      selectedColor: theme.colorScheme.primary.withOpacity(0.24),
      side: BorderSide(
        color: selected
            ? theme.colorScheme.primary
            : theme.colorScheme.outline.withOpacity(0.25),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _LeaderboardTab extends StatelessWidget {
  final LeaderboardPeriod period;

  const _LeaderboardTab({required this.period});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final sheetState =
        context.findAncestorStateOfType<_MachineLeaderboardSheetState>();
    final notifier = sheetState?._notifier;
    if (notifier == null) {
      return const Center(child: CircularProgressIndicator());
    }
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
    return ListView.separated(
      padding: const EdgeInsets.only(top: 4, bottom: 24),
      physics: const BouncingScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final item = items[index];
        final entry = item.value;
        final rank = item.key + 1;
        if (index == 0) {
          return _HighlightedLeaderboardCard(
            entry: entry,
            numberFormat: numberFormat,
            dateFormat: dateFormat,
            loc: loc,
            theme: theme,
          );
        }
        return _LeaderboardEntryCard(
          entry: entry,
          numberFormat: numberFormat,
          dateFormat: dateFormat,
          loc: loc,
          rank: rank,
        );
      },
    );
  }
}

class _HighlightedLeaderboardCard extends StatelessWidget {
  final LeaderboardEntry entry;
  final NumberFormat numberFormat;
  final DateFormat dateFormat;
  final AppLocalizations loc;
  final ThemeData theme;

  const _HighlightedLeaderboardCard({
    required this.entry,
    required this.numberFormat,
    required this.dateFormat,
    required this.loc,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final onPrimary = theme.colorScheme.onPrimary;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.28),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: onPrimary.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.emoji_events_rounded,
                  color: onPrimary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _LeaderboardEntryTitle(
                  entry: entry,
                  numberFormat: numberFormat,
                  loc: loc,
                  highlight: true,
                ),
              ),
              Text(
                _formatPrimaryScore(entry, numberFormat, loc),
                style: theme.textTheme.headlineSmall?.copyWith(
                      color: onPrimary,
                      fontWeight: FontWeight.w800,
                    ) ??
                    TextStyle(
                      color: onPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _LeaderboardEntrySubtitle(
            entry: entry,
            dateFormat: dateFormat,
            loc: loc,
            highlight: true,
          ),
        ],
      ),
    );
  }
}

class _LeaderboardEntryCard extends StatelessWidget {
  final LeaderboardEntry entry;
  final NumberFormat numberFormat;
  final DateFormat dateFormat;
  final AppLocalizations loc;
  final int rank;

  const _LeaderboardEntryCard({
    required this.entry,
    required this.numberFormat,
    required this.dateFormat,
    required this.loc,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.95),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RankBadge(rank: rank),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _LeaderboardEntryTitle(
                        entry: entry,
                        numberFormat: numberFormat,
                        loc: loc,
                        highlight: false,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _formatPrimaryScore(entry, numberFormat, loc),
                      style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _LeaderboardEntrySubtitle(
                  entry: entry,
                  dateFormat: dateFormat,
                  loc: loc,
                  highlight: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;

  const _RankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.secondaryContainer,
            theme.colorScheme.secondary.withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        '$rank',
        style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w800,
            ) ??
            TextStyle(
              color: theme.colorScheme.onSecondaryContainer,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _LeaderboardEntryTitle extends StatelessWidget {
  final LeaderboardEntry entry;
  final NumberFormat numberFormat;
  final AppLocalizations loc;
  final bool highlight;

  const _LeaderboardEntryTitle({
    required this.entry,
    required this.numberFormat,
    required this.loc,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleColor = highlight
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;
    final secondaryColor = highlight
        ? theme.colorScheme.onPrimary.withOpacity(0.85)
        : theme.colorScheme.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          entry.attempt.username,
          style: theme.textTheme.titleMedium?.copyWith(
                color: titleColor,
                fontWeight: FontWeight.w700,
              ),
        ),
        Text(
          '${numberFormat.format(entry.attempt.e1rm)} kg',
          style: theme.textTheme.bodyMedium?.copyWith(
                color: secondaryColor,
              ),
        ),
      ],
    );
  }
}

class _LeaderboardEntrySubtitle extends StatelessWidget {
  final LeaderboardEntry entry;
  final DateFormat dateFormat;
  final AppLocalizations loc;
  final bool highlight;

  const _LeaderboardEntrySubtitle({
    required this.entry,
    required this.dateFormat,
    required this.loc,
    required this.highlight,
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

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: details
          .map(
            (detail) => _InfoPill(
              label: detail,
              highlight: highlight,
            ),
          )
          .toList(),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String label;
  final bool highlight;

  const _InfoPill({required this.label, required this.highlight});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = highlight
        ? theme.colorScheme.onPrimary.withOpacity(0.18)
        : theme.colorScheme.surfaceVariant.withOpacity(0.6);
    final foreground = highlight
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
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

String _resolveLeaderboardTitle(
  AppLocalizations loc,
  String device,
  LeaderboardGenderFilter filter,
) {
  switch (filter) {
    case LeaderboardGenderFilter.male:
      return loc.deviceLeaderboardTitleKing(device);
    case LeaderboardGenderFilter.female:
      return loc.deviceLeaderboardTitleQueen(device);
    case LeaderboardGenderFilter.all:
      return loc.deviceLeaderboardTitle(device);
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:tapem/core/logging/elog.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/features/story_card/presentation/widgets/session_story_modal.dart';
import 'package:tapem/features/story_card/session_story_controller.dart';
import 'package:tapem/features/story_card/session_story_share_service.dart';
import 'package:tapem/features/story_card/story_link_builder.dart';
import 'package:tapem/l10n/app_localizations.dart';

import '../../data/story_analytics_service.dart';
import '../../domain/story_timeline_entry.dart';
import '../../domain/story_timeline_filter.dart';
import '../controllers/story_timeline_controller.dart';

class StoryTimelineScreen extends StatelessWidget {
  const StoryTimelineScreen({super.key, this.userIdOverride, this.gymIds});

  final String? userIdOverride;
  final List<String>? gymIds;

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider?>();
    final userId = userIdOverride ?? auth?.userId ?? '';
    final gyms = <String>{
      ...(gymIds ?? auth?.gymCodes ?? const <String>[]),
    }.where((element) => element.trim().isNotEmpty).toList()
      ..sort();

    return ChangeNotifierProvider<StoryTimelineController>(
      key: ValueKey(userId),
      create: (_) => StoryTimelineController(userId: userId)..init(),
      child: _StoryTimelineView(gymIds: gyms),
    );
  }
}

class _StoryTimelineView extends StatefulWidget {
  const _StoryTimelineView({required this.gymIds});

  final List<String> gymIds;

  @override
  State<_StoryTimelineView> createState() => _StoryTimelineViewState();
}

class _StoryTimelineViewState extends State<_StoryTimelineView> {
  final ScrollController _scrollController = ScrollController();
  final SessionStoryShareService _shareService = SessionStoryShareService();
  final StoryLinkBuilder _linkBuilder = StoryLinkBuilder();
  final StoryAnalyticsService _analytics = StoryAnalyticsService();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    final controller = context.read<StoryTimelineController>();
    if (_scrollController.position.extentAfter < 400) {
      controller.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.storiesTitle),
      ),
      body: Consumer<StoryTimelineController>(
        builder: (context, controller, _) {
          final entries = controller.entries;
          final isInitialLoading = controller.isLoading && entries.isEmpty;
          return Column(
            children: [
              _MetricsStrip(metrics: controller.metrics, loc: loc),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: _FilterRow(
                  controller: controller,
                  loc: loc,
                  gymIds: widget.gymIds,
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => controller.refresh(preferCache: false),
                  child: isInitialLoading
                      ? const _CenteredLoader()
                      : entries.isEmpty
                          ? _EmptyState(loc: loc, error: controller.error)
                          : ListView.separated(
                              controller: _scrollController,
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                              itemCount: entries.length + (controller.hasMore ? 1 : 0),
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                if (index >= entries.length) {
                                  return const _LoadMoreIndicator();
                                }
                                final entry = entries[index];
                                return _StoryTimelineTile(
                                  entry: entry,
                                  onTap: () => _openStory(entry),
                                );
                              },
                            ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openStory(StoryTimelineEntry entry) async {
    final controller = context.read<SessionStoryController>();
    final loc = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final auth = context.read<AuthProvider?>();
    final userId = auth?.userId ?? '';
    try {
      final story = await controller.loadStoryById(entry.sessionId);
      await SessionStoryModal.show(
        context: context,
        story: story,
        shareService: _shareService,
        buildLink: () => _linkBuilder.build(story),
        onViewed: () {
          elogUi('storycard_shown', {
            'sessionId': story.sessionId,
            'origin': 'timeline',
            'xpTotal': story.xpTotal,
            'prCount': story.badges.length,
          });
          _analytics.trackStoryViewed(userId: userId, sessionId: story.sessionId);
        },
        onShared: (target) {
          elogUi('storycard_shared', {
            'sessionId': story.sessionId,
            'target': target ?? 'system',
          });
          _analytics.trackStoryShared(userId: userId, sessionId: story.sessionId, target: target);
        },
        onSaved: () {
          elogUi('storycard_saved', {'sessionId': story.sessionId});
          _analytics.trackStorySaved(userId: userId, sessionId: story.sessionId);
        },
      );
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(loc.storycardLoadError)),
      );
    }
  }
}

class _MetricsStrip extends StatelessWidget {
  const _MetricsStrip({required this.metrics, required this.loc});

  final StoryTimelineMetrics? metrics;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    if (metrics == null) {
      return const SizedBox(height: 8);
    }
    final data = metrics!;
    final localeName = Localizations.localeOf(context).toString();
    final percentFormat = NumberFormat.percentPattern(localeName);
    final numberFormat = NumberFormat.decimalPattern(localeName);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: _MetricCard(
              title: loc.storiesKpiShareRate,
              value: percentFormat.format(data.shareRate.clamp(0, 1)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _MetricCard(
              title: loc.storiesKpiPrRate,
              value: numberFormat.format(data.prSessionsPerHundred),
              suffix: ' /100',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _MetricCard(
              title: loc.storiesKpiAverageXp,
              value: numberFormat.format(data.averageXpPerSession),
              suffix: ' XP',
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.title, required this.value, this.suffix});

  final String title;
  final String value;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: onSurface.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(color: onSurface.withOpacity(0.7)),
          ),
          const SizedBox(height: 6),
          Text(
            '$value${suffix ?? ''}',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.controller, required this.loc, required this.gymIds});

  final StoryTimelineController controller;
  final AppLocalizations loc;
  final List<String> gymIds;

  @override
  Widget build(BuildContext context) {
    final filter = controller.filter;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _DropdownField<StoryTimelinePrFilter>(
                label: loc.storiesFilterPrType,
                value: filter.prFilter,
                items: StoryTimelinePrFilter.values
                    .map((value) => DropdownMenuItem(
                          value: value,
                          child: Text(_prLabel(value, loc)),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    controller.applyFilter(filter.copyWith(prFilter: value));
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DropdownField<StoryTimelineRange>(
                label: loc.storiesFilterRange,
                value: filter.range,
                items: StoryTimelineRange.values
                    .map((value) => DropdownMenuItem(
                          value: value,
                          child: Text(_rangeLabel(value, loc)),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    controller.applyFilter(filter.copyWith(range: value));
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _DropdownField<String?>(
          label: loc.storiesFilterGym,
          value: filter.gymId,
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text(loc.storiesFilterGymAll),
            ),
            ...gymIds.map(
              (gymId) => DropdownMenuItem<String?>(
                value: gymId,
                child: Text(gymId),
              ),
            ),
          ],
          onChanged: (value) => controller.updateGym(value),
        ),
      ],
    );
  }

  String _prLabel(StoryTimelinePrFilter filter, AppLocalizations loc) {
    switch (filter) {
      case StoryTimelinePrFilter.all:
        return loc.storiesFilterPrAll;
      case StoryTimelinePrFilter.prsOnly:
        return loc.storiesFilterPrOnly;
      case StoryTimelinePrFilter.firsts:
        return loc.storiesFilterPrFirsts;
      case StoryTimelinePrFilter.strength:
        return loc.storiesFilterPrStrength;
      case StoryTimelinePrFilter.volume:
        return loc.storiesFilterPrVolume;
    }
  }

  String _rangeLabel(StoryTimelineRange range, AppLocalizations loc) {
    switch (range) {
      case StoryTimelineRange.last30Days:
        return loc.storiesFilterRange30;
      case StoryTimelineRange.last90Days:
        return loc.storiesFilterRange90;
      case StoryTimelineRange.thisYear:
        return loc.storiesFilterRangeYear;
      case StoryTimelineRange.allTime:
        return loc.storiesFilterRangeAll;
    }
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelMedium),
        const SizedBox(height: 4),
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}

class _StoryTimelineTile extends StatelessWidget {
  const _StoryTimelineTile({required this.entry, required this.onTap});

  final StoryTimelineEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final localeName = Localizations.localeOf(context).toString();
    final dateFormat = DateFormat.yMMMd(localeName);
    final xpFormat = NumberFormat.decimalPattern(localeName);
    final prLabel = entry.prCount > 0
        ? loc.storiesListPrCount(entry.prCount)
        : loc.storiesListNoPrs;
    final xpLabel = loc.storiesListXp(xpFormat.format(entry.xpTotal.round()));
    final colors = entry.previewColors.length >= 2
        ? entry.previewColors
        : [...entry.previewColors, entry.previewColors.first];

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${dateFormat.format(entry.createdAt)} • ${entry.gymName ?? entry.gymId ?? ''}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white.withOpacity(0.85),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _InfoChip(icon: Icons.star, label: xpLabel),
                const SizedBox(width: 8),
                _InfoChip(icon: Icons.military_tech, label: prLabel),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.loc, this.error});

  final AppLocalizations loc;
  final Object? error;

  @override
  Widget build(BuildContext context) {
    final message = error != null ? loc.storiesErrorState : loc.storiesEmptyState;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
          child: Column(
            children: [
              Icon(Icons.auto_stories, size: 64, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CenteredLoader extends StatelessWidget {
  const _CenteredLoader();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _LoadMoreIndicator extends StatelessWidget {
  const _LoadMoreIndicator();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

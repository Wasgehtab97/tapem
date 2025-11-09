import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:intl/intl.dart';

import '../../../../core/theme/app_brand_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/community_stats.dart';
import '../../domain/models/feed_event.dart';
import '../providers/community_providers.dart';

class CommunityScreen extends riverpod.ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  riverpod.ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends riverpod.ConsumerState<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: CommunityPeriod.values.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final brandColor = brandTheme?.outline ?? theme.colorScheme.secondary;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.communityTitle),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: brandColor,
          labelColor: brandColor,
          unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
          tabs: [
            Tab(text: loc.communityTabToday),
            Tab(text: loc.communityTabWeek),
            Tab(text: loc.communityTabMonth),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _CommunityTab(period: CommunityPeriod.today),
                _CommunityTab(period: CommunityPeriod.week),
                _CommunityTab(period: CommunityPeriod.month),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommunityTab extends riverpod.ConsumerWidget {
  const _CommunityTab({required this.period});

  final CommunityPeriod period;

  @override
  Widget build(BuildContext context, riverpod.WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final statsValue = ref.watch(communityStatsProvider(period));
    final feedValue = ref.watch(communityFeedProvider);

    return statsValue.when(
      loading: () => const _CommunityLoadingView(),
      error: (error, stackTrace) => _CommunityScrollableError(
        message: loc.communityErrorState,
        onRetry: () {
          ref.invalidate(communityStatsProvider(period));
          ref.invalidate(communityFeedProvider);
        },
      ),
      data: (stats) {
        return _CommunityContent(
          stats: stats,
          feedValue: feedValue,
          onRetryStats: () => ref.invalidate(communityStatsProvider(period)),
          onRetryFeed: () => ref.invalidate(communityFeedProvider),
        );
      },
    );
  }
}

class _CommunityContent extends StatelessWidget {
  const _CommunityContent({
    required this.stats,
    required this.feedValue,
    required this.onRetryStats,
    required this.onRetryFeed,
  });

  final CommunityStats stats;
  final riverpod.AsyncValue<List<FeedEvent>> feedValue;
  final VoidCallback onRetryStats;
  final VoidCallback onRetryFeed;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final brandColor = brandTheme?.outline ?? theme.colorScheme.secondary;

    final slivers = <Widget>[
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
        ),
        sliver: SliverToBoxAdapter(
          child: stats.hasData
              ? _CommunityKpiSection(stats: stats, accentColor: brandColor)
              : _CommunityPlaceholder(message: loc.communityEmptyState),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm,
          0,
          AppSpacing.sm,
          AppSpacing.lg,
        ),
        sliver: SliverToBoxAdapter(
          child: _CommunityFeedCard(
            highlightColor: brandColor,
            feedValue: feedValue,
            onRetry: onRetryFeed,
          ),
        ),
      ),
    ];

    return RefreshIndicator(
      onRefresh: () async {
        await Future<void>.microtask(() {
          onRetryStats();
          onRetryFeed();
        });
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: slivers,
      ),
    );
  }
}

class _CommunityLoadingView extends StatelessWidget {
  const _CommunityLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}

class _CommunityScrollableError extends StatelessWidget {
  const _CommunityScrollableError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final accent = brandTheme?.outline ?? theme.colorScheme.secondary;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.xl),
          Text(
            message,
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            child: TextButton(
              onPressed: onRetry,
              child: Text(
                AppLocalizations.of(context)!.communityRetryButton,
                style: TextStyle(color: accent),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}


class _CommunityKpiSection extends StatelessWidget {
  const _CommunityKpiSection({required this.stats, required this.accentColor});

  final CommunityStats stats;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final numberFormat = NumberFormat.decimalPattern(localeName);
    final decimalFormat = NumberFormat.decimalPatternDigits(
      locale: localeName,
      decimalDigits: 1,
    );

    final metrics = [
      _CommunityMetric(
        label: loc.communityKpiSessions,
        value: numberFormat.format(stats.totalSessions),
      ),
      _CommunityMetric(
        label: loc.communityKpiExercises,
        value: numberFormat.format(stats.totalExercises),
      ),
      _CommunityMetric(
        label: loc.communityKpiSets,
        value: numberFormat.format(stats.totalSets),
      ),
      _CommunityMetric(
        label: loc.communityKpiReps,
        value: numberFormat.format(stats.totalReps),
      ),
      _CommunityMetric(
        label: loc.communityKpiVolume,
        value: _formatCommunityVolume(
          volume: stats.totalVolumeKg,
          numberFormat: numberFormat,
          decimalFormat: decimalFormat,
        ),
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.cardLg),
        border: Border.all(color: accentColor.withOpacity(0.25)),
        color: theme.colorScheme.surfaceVariant.withOpacity(0.25),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.communityKpiHeadline,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth;
              final columns = maxWidth >= 900
                  ? 5
                  : maxWidth >= 620
                      ? 3
                      : 2;
              final itemWidth = (maxWidth - AppSpacing.sm * (columns - 1)) / columns;
              return Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: metrics
                    .map(
                      (metric) => SizedBox(
                        width: itemWidth.clamp(140.0, maxWidth).toDouble(),
                        child: _CommunityMetricTile(
                          metric: metric,
                          accentColor: accentColor,
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CommunityMetric {
  const _CommunityMetric({required this.label, required this.value});

  final String label;
  final String value;
}

class _CommunityMetricTile extends StatelessWidget {
  const _CommunityMetricTile({required this.metric, required this.accentColor});

  final _CommunityMetric metric;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: accentColor.withOpacity(0.28)),
        color: accentColor.withOpacity(0.08),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            metric.value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            metric.label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.72),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _CommunityFeedCard extends StatelessWidget {
  const _CommunityFeedCard({
    required this.highlightColor,
    required this.feedValue,
    required this.onRetry,
  });

  final Color highlightColor;
  final riverpod.AsyncValue<List<FeedEvent>> feedValue;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final dateFormat = DateFormat.yMMMd(loc.localeName);

    Widget buildBody(List<FeedEvent> events) {
      if (events.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Center(
            child: Text(
              loc.communityFeedEmpty,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
        );
      }
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return _CommunityFeedTile(
            event: event,
            dateFormat: dateFormat,
            highlightColor: highlightColor,
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
      );
    }

    Widget buildError(Object error, StackTrace? stackTrace) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Column(
          children: [
            Text(
              loc.communityFeedError,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: onRetry,
              child: Text(loc.communityRetryButton, style: TextStyle(color: highlightColor)),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            highlightColor.withOpacity(0.28),
            theme.colorScheme.surface.withOpacity(0.96),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.cardLg),
        border: Border.all(color: highlightColor.withOpacity(0.26)),
        boxShadow: [
          BoxShadow(
            color: highlightColor.withOpacity(0.25),
            blurRadius: 26,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      highlightColor,
                      highlightColor.withOpacity(0.75),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: highlightColor.withOpacity(0.4),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(AppSpacing.xs * 0.75),
                child: const Icon(Icons.bolt, color: Colors.black87),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.communityFeedTitle,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      loc.communityTitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.65),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: highlightColor.withOpacity(0.9),
                  boxShadow: [
                    BoxShadow(
                      color: highlightColor.withOpacity(0.6),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            height: 1.2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  highlightColor.withOpacity(0.0),
                  highlightColor.withOpacity(0.4),
                  highlightColor.withOpacity(0.0),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          feedValue.when(
            data: buildBody,
            loading: () => const _CommunityFeedSkeleton(),
            error: buildError,
          ),
        ],
      ),
    );
  }
}

class _CommunityKpiDescriptor {
  const _CommunityKpiDescriptor({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _CommunityKpiCard extends StatelessWidget {
  const _CommunityKpiCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
    this.isActive = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accentColor;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeOpacity = isActive ? 0.42 : 0.24;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withOpacity(activeOpacity),
            accentColor.withOpacity(isActive ? 0.12 : 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.cardLg),
        border: Border.all(color: accentColor.withOpacity(isActive ? 0.38 : 0.22)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(isActive ? 0.32 : 0.18),
            blurRadius: isActive ? 26 : 16,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      constraints: const BoxConstraints(minHeight: 190),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  accentColor,
                  accentColor.withOpacity(0.65),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.32),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.all(AppSpacing.xs),
            child: Icon(icon, color: Colors.black87),
          ),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}


class _CommunityFeedTile extends StatelessWidget {
  const _CommunityFeedTile({
    required this.event,
    required this.dateFormat,
    required this.highlightColor,
  });

  final FeedEvent event;
  final DateFormat dateFormat;
  final Color highlightColor;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final eventDate = _resolveEventDate()?.toLocal();
    final createdLabel = eventDate != null ? dateFormat.format(eventDate) : '–';
    final headline = loc.communityFeedTrainingDayHeadline;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: highlightColor.withOpacity(0.18)),
        color: highlightColor.withOpacity(0.1),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: highlightColor.withOpacity(0.85),
            ),
            child: Icon(
              event.type == FeedEventType.milestone
                  ? Icons.emoji_events
                  : Icons.calendar_today,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  headline,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  createdLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  DateTime? _resolveEventDate() {
    if (event.createdAt != null) {
      return event.createdAt;
    }
    if (event.dayKey.isNotEmpty) {
      return DateTime.tryParse(event.dayKey);
    }
    return null;
  }
}

class _CommunityPlaceholder extends StatelessWidget {
  const _CommunityPlaceholder({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.6),
        borderRadius: BorderRadius.circular(AppRadius.cardLg),
      ),
      child: Text(
        message,
        style: theme.textTheme.bodyMedium,
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _CommunityFeedSkeleton extends StatelessWidget {
  const _CommunityFeedSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = theme.colorScheme.surfaceVariant.withOpacity(0.4);

    return Column(
      children: List.generate(4, (index) {
        final opacity = 0.34 - (index * 0.04);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.card),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  baseColor.withOpacity(0.9),
                  baseColor.withOpacity(0.4),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: baseColor,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Container(
                        height: 16,
                        decoration: BoxDecoration(
                          color: baseColor.withOpacity(0.7 - (index * 0.1)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      width: 36,
                      height: 12,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: baseColor.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Container(
                  height: 12,
                  width: 140,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: baseColor.withOpacity(
                      opacity.clamp(0.1, 0.4).toDouble(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

String _formatCommunityVolume({
  required double volume,
  required NumberFormat numberFormat,
  required NumberFormat decimalFormat,
}) {
  return volume % 1 == 0
      ? numberFormat.format(volume.round())
      : decimalFormat.format(volume);
}

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
          AppSpacing.sm,
          AppSpacing.sm,
          AppSpacing.md,
        ),
        sliver: SliverToBoxAdapter(
          child: stats.hasData
              ? _CommunityKpiSection(stats: stats)
              : _CommunityPlaceholder(message: loc.communityEmptyState),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.sm, 0, AppSpacing.sm, AppSpacing.sm),
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
  const _CommunityKpiSection({required this.stats});

  final CommunityStats stats;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final brandColor = brandTheme?.outline ?? theme.colorScheme.secondary;

    final localeName = Localizations.localeOf(context).toLanguageTag();
    final numberFormat = NumberFormat.decimalPattern(localeName);
    final compactVolumeFormat = NumberFormat.decimalPatternDigits(
      locale: localeName,
      decimalDigits: 1,
    );

    final volume = stats.totalVolumeKg;
    final formattedVolume = _formatCommunityVolume(
      volume: volume,
      numberFormat: numberFormat,
      decimalFormat: compactVolumeFormat,
    );

    final cards = [
      _CommunityKpiCard(
        icon: Icons.repeat,
        label: loc.communityKpiReps,
        value: numberFormat.format(stats.totalReps),
        accentColor: brandColor,
      ),
      _CommunityKpiCard(
        icon: Icons.fitness_center,
        label: loc.communityKpiVolume,
        value: formattedVolume,
        accentColor: brandColor,
      ),
      _CommunityKpiCard(
        icon: Icons.celebration,
        label: loc.communityKpiWorkouts,
        value: numberFormat.format(stats.workoutCount),
        accentColor: brandColor,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        if (isWide) {
          return Row(
            children: [
              for (var i = 0; i < cards.length; i++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: i == cards.length - 1 ? 0 : AppSpacing.sm,
                    ),
                    child: cards[i],
                  ),
                ),
            ],
          );
        }
        return Column(
          children: [
            for (var i = 0; i < cards.length; i++)
              Padding(
                padding: EdgeInsets.only(
                  bottom: i == cards.length - 1 ? 0 : AppSpacing.sm,
                ),
                child: cards[i],
              ),
          ],
        );
      },
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
    final numberFormat = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final timeFormat = DateFormat.Hm(loc.localeName);

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
            numberFormat: numberFormat,
            timeFormat: timeFormat,
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
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            highlightColor.withOpacity(0.2),
            theme.colorScheme.surface.withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.cardLg),
        border: Border.all(color: highlightColor.withOpacity(0.22)),
        boxShadow: [
          BoxShadow(
            color: highlightColor.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      highlightColor,
                      highlightColor.withOpacity(0.7),
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(AppSpacing.xs),
                child: const Icon(Icons.broadcast_on_home, color: Colors.black),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                loc.communityFeedTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
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

class _CommunityKpiCard extends StatelessWidget {
  const _CommunityKpiCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        accentColor.withOpacity(0.26),
        accentColor.withOpacity(0.08),
      ],
    );
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppRadius.cardLg),
        border: Border.all(color: accentColor.withOpacity(0.22)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.2),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
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
                  color: accentColor.withOpacity(0.3),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(AppSpacing.xs),
            child: Icon(icon, color: Colors.black87),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
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
    required this.numberFormat,
    required this.timeFormat,
    required this.highlightColor,
  });

  final FeedEvent event;
  final NumberFormat numberFormat;
  final DateFormat timeFormat;
  final Color highlightColor;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final displayName = event.displayName;
    final reps = numberFormat.format(event.reps);
    final volume = numberFormat.format(event.volumeKg.round());
    final created = event.createdAt != null
        ? timeFormat.format(event.createdAt!.toLocal())
        : '–';
    final detailPills = <Widget>[
      if (event.deviceName != null && event.deviceName!.isNotEmpty)
        _CommunityDetailPill(
          text: event.deviceName!,
          accentColor: highlightColor,
          backgroundOpacity: 0.2,
        ),
      _CommunityDetailPill(
        text: loc.communityFeedRepsLabel(reps),
        accentColor: highlightColor,
        backgroundOpacity: 0.14,
      ),
      _CommunityDetailPill(
        text: loc.communityFeedVolumeLabel(volume),
        accentColor: highlightColor,
        backgroundOpacity: 0.14,
      ),
    ];

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(color: highlightColor.withOpacity(0.12)),
      ),
      tileColor: theme.colorScheme.surfaceVariant.withOpacity(0.35),
      minLeadingWidth: 0,
      leading: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              highlightColor,
              highlightColor.withOpacity(0.7),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: highlightColor.withOpacity(0.32),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(Icons.bolt, color: Colors.black87),
      ),
      title: displayName == null
          ? null
          : Text(
              displayName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 4),
          Wrap(
            spacing: AppSpacing.xs / 2,
            runSpacing: 6,
            children: detailPills,
          ),
          if (event.funnyText != null && event.funnyText!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              event.funnyText!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
      trailing: Text(
        created,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
      visualDensity: VisualDensity.compact,
    );
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
    return Column(
      children: List.generate(6, (index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceVariant
                      .withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Container(
                  height: 18,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceVariant
                        .withOpacity(0.35),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _CommunityDetailPill extends StatelessWidget {
  const _CommunityDetailPill({
    required this.text,
    required this.accentColor,
    this.icon,
    this.backgroundOpacity = 0.16,
  });

  final String text;
  final Color accentColor;
  final IconData? icon;
  final double backgroundOpacity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm * 0.75,
        vertical: AppSpacing.xs * 0.45,
      ),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(backgroundOpacity),
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(
          color: accentColor.withOpacity(backgroundOpacity + 0.08),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 14,
              color: theme.colorScheme.onSurface,
            ),
            const SizedBox(width: 6),
          ],
          Text(
            text,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
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

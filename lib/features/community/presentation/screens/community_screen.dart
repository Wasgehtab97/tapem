import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:intl/intl.dart';

import '../../../../core/theme/app_brand_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/brand_gradient_text.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../profile/presentation/widgets/calendar.dart';
import '../../../profile/presentation/widgets/calendar_popup.dart';
import '../../domain/models/community_stats.dart';
import '../providers/community_providers.dart';

class CommunityScreen extends riverpod.ConsumerStatefulWidget {
  const CommunityScreen({super.key, this.onExitToProfile});

  final VoidCallback? onExitToProfile;

  @override
  riverpod.ConsumerState<CommunityScreen> createState() =>
      _CommunityScreenState();
}

class _CommunityScreenState extends riverpod.ConsumerState<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  void _handleBackPressed() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    widget.onExitToProfile?.call();
  }

  Widget? _buildLeadingBackButton() {
    final canPop = Navigator.of(context).canPop();
    if (!canPop && widget.onExitToProfile == null) {
      return null;
    }
    return IconButton(
      onPressed: _handleBackPressed,
      icon: const Icon(Icons.chevron_left_rounded),
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: CommunityPeriod.values.length,
      vsync: this,
    );
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
        automaticallyImplyLeading: false,
        leading: _buildLeadingBackButton(),
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

    return statsValue.when(
      loading: () => const _CommunityLoadingView(),
      error: (error, stackTrace) => _CommunityScrollableError(
        message: loc.communityErrorState,
        onRetry: () {
          ref.invalidate(communityStatsProvider(period));
        },
      ),
      data: (stats) {
        return _CommunityContent(
          stats: stats,
          onRetryStats: () => ref.invalidate(communityStatsProvider(period)),
        );
      },
    );
  }
}

class _CommunityContent extends StatelessWidget {
  const _CommunityContent({required this.stats, required this.onRetryStats});

  final CommunityStats stats;
  final VoidCallback onRetryStats;

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
          child: _CommunityFeedCard(highlightColor: brandColor),
        ),
      ),
    ];

    return RefreshIndicator(
      onRefresh: () async {
        await Future<void>.microtask(() {
          onRetryStats();
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
    return const Center(child: CircularProgressIndicator());
  }
}

class _CommunityScrollableError extends StatelessWidget {
  const _CommunityScrollableError({
    required this.message,
    required this.onRetry,
  });

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
              final itemWidth =
                  (maxWidth - AppSpacing.sm * (columns - 1)) / columns;
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

class _CommunityFeedCard extends riverpod.ConsumerWidget {
  const _CommunityFeedCard({required this.highlightColor});

  final Color highlightColor;

  @override
  Widget build(BuildContext context, riverpod.WidgetRef ref) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final calendarYear = DateTime.now().year;
    final activeUsersValue = ref.watch(
      communityActiveUsersByDayProvider(calendarYear),
    );
    final activeUsersByDay = activeUsersValue.valueOrNull ?? const {};
    final trainingDates = activeUsersByDay.entries
        .where((entry) => entry.value > 0)
        .map((entry) => entry.key)
        .toList(growable: false);
    final hasCalendarData = trainingDates.isNotEmpty;

    Future<void> openCalendar() async {
      final selected = await showDialog<DateTime>(
        context: context,
        barrierColor: Colors.black54,
        builder: (_) => CalendarPopup(
          trainingDates: trainingDates,
          initialYear: calendarYear,
          userId: '',
          navigateOnTap: false,
        ),
      );
      if (selected == null) {
        return;
      }
      final dateKey = DateFormat('yyyy-MM-dd').format(selected);
      final count = activeUsersByDay[dateKey] ?? 0;
      _showActiveUsersSheet(context, count);
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            highlightColor.withOpacity(0.18),
            theme.colorScheme.surface.withOpacity(0.92),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.cardLg),
        border: Border.all(color: highlightColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 28,
            offset: const Offset(0, 16),
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
                    colors: [highlightColor, highlightColor.withOpacity(0.75)],
                  ),
                ),
                padding: const EdgeInsets.all(AppSpacing.xs * 0.75),
                child: const Icon(Icons.bolt, color: Colors.black87),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BrandGradientText(
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
          activeUsersValue.when(
            data: (_) => AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: hasCalendarData ? 1 : 0.5,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: openCalendar,
                child: Calendar(
                  trainingDates: trainingDates,
                  showNavigation: false,
                  year: calendarYear,
                ),
              ),
            ),
            loading: () => const _CommunityCalendarSkeleton(),
            error: (error, stackTrace) => Padding(
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
                    onPressed: () => ref.invalidate(
                      communityActiveUsersByDayProvider(calendarYear),
                    ),
                    child: Text(
                      loc.communityRetryButton,
                      style: TextStyle(color: highlightColor),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void _showActiveUsersSheet(BuildContext context, int count) {
  final theme = Theme.of(context);
  final loc = AppLocalizations.of(context)!;
  final message = count == 1
      ? loc.communityCalendarCountOne
      : loc.communityCalendarCountOther(count);
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: theme.colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppRadius.cardLg),
      ),
    ),
    builder: (context) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              BrandGradientText(
                loc.communityCalendarTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
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

class _CommunityCalendarSkeleton extends StatelessWidget {
  const _CommunityCalendarSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = theme.colorScheme.surfaceVariant.withOpacity(0.35);
    return Container(
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.cardLg),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [baseColor.withOpacity(0.7), baseColor.withOpacity(0.35)],
        ),
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

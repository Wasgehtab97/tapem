import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/providers/profile_provider.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/widgets/brand_gradient_card.dart';
import 'package:tapem/core/logging/elog.dart';
import 'package:tapem/l10n/app_localizations.dart';

class ProfileStatsScreen extends StatefulWidget {
  const ProfileStatsScreen({super.key});

  @override
  State<ProfileStatsScreen> createState() => _ProfileStatsScreenState();
}

class _ProfileStatsScreenState extends State<ProfileStatsScreen> with RouteAware {
  ModalRoute<dynamic>? _route;
  bool _hasRequestedInitialLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null && _route != route) {
      if (_route != null) {
        routeObserver.unsubscribe(this);
      }
      _route = route;
      routeObserver.subscribe(this, route);
      if (route.isCurrent) {
        _ensureInitialLoad();
      }
    }
  }

  @override
  void dispose() {
    if (_route != null) {
      routeObserver.unsubscribe(this);
    }
    super.dispose();
  }

  void _ensureInitialLoad() {
    if (_hasRequestedInitialLoad) {
      return;
    }
    _hasRequestedInitialLoad = true;
    _loadSummaries();
  }

  void _loadSummaries({bool forceRemote = false}) {
    if (!mounted) {
      return;
    }
    context
        .read<ProfileProvider>()
        .loadTrainingDates(context, forceRefresh: forceRemote);
  }

  void _refreshSummaries() {
    _loadSummaries(forceRemote: true);
  }

  @override
  void didPush() {
    _ensureInitialLoad();
  }

  @override
  void didPopNext() {
    _loadSummaries();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ProfileProvider>();
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final brandColor =
        theme.extension<AppBrandTheme>()?.outline ?? theme.colorScheme.secondary;
    final numberFormat = NumberFormat(
      '0.0',
      Localizations.localeOf(context).toString(),
    );

    final totalTrainingDays = prov.totalTrainingDays;
    final avgTrainingDays = prov.averageTrainingDaysPerWeek;
    final favoriteExercise =
        prov.favoriteExerciseName ?? loc.profileStatsFavoriteExerciseFallback;

    String formatAverage(double value) {
      if (value == 0) {
        return '0';
      }
      return numberFormat.format(value);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.profileStatsTitle),
        centerTitle: true,
        foregroundColor: brandColor,
      ),
      body: DefaultTextStyle.merge(
        style: TextStyle(color: brandColor),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: _buildBody(
              context,
              loc,
              prov,
              totalTrainingDays,
              avgTrainingDays,
              favoriteExercise,
              formatAverage,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations loc,
    ProfileProvider prov,
    int totalTrainingDays,
    double avgTrainingDays,
    String favoriteExercise,
    String Function(double value) formatAverage,
  ) {
    final theme = Theme.of(context);
    if (prov.error != null) {
      return _buildErrorState(context, loc, prov);
    }

    if (prov.isLoading && !prov.hasSummaries) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!prov.hasSummaries) {
      return _buildEmptyState(context, loc, prov);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          loc.historyOverviewTitle,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            _kpiRing(
              context,
              loc.profileStatsTotalTrainingDays,
              totalTrainingDays.toString(),
            ),
            _kpiRing(
              context,
              loc.profileStatsAverageTrainingDaysPerWeek,
              formatAverage(avgTrainingDays),
            ),
            _kpiRing(
              context,
              loc.profileStatsFavoriteExercise,
              favoriteExercise,
              onTap: () => _showFavoriteExercisesDialog(context, prov, loc),
            ),
            _powerliftingButton(context, loc),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (prov.hasMoreSummaries)
          OutlinedButton.icon(
            icon: const Icon(Icons.expand_more_rounded),
            label: Text(loc.profileLoadMoreButton),
            onPressed: prov.isLoadingMore
                ? null
                : () {
                    prov.loadMoreTrainingSummaries(context);
                  },
          ),
        if (prov.isLoadingMore)
          const Padding(
            padding: EdgeInsets.only(top: AppSpacing.sm),
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    AppLocalizations loc,
    ProfileProvider prov,
  ) {
    final theme = Theme.of(context);
    final surfaceVariant = theme.colorScheme.surfaceVariant.withOpacity(
      theme.brightness == Brightness.dark ? 0.35 : 0.6,
    );

    return Card(
      color: surfaceVariant,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_graph_outlined,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    loc.profileStatsNoSummaries,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              loc.profileStatsSummariesPending,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: prov.isLoading ? null : _refreshSummaries,
                icon: const Icon(Icons.refresh),
                label: Text(loc.profileStatsRefreshSummaries),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    AppLocalizations loc,
    ProfileProvider prov,
  ) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(
          Icons.error_outline,
          color: theme.colorScheme.error,
          size: 48,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          loc.profileStatsError,
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          prov.error ?? '',
          style: theme.textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: prov.isLoading ? null : _loadSummaries,
          icon: const Icon(Icons.refresh),
          label: Text(loc.profileStatsRetry),
        ),
      ],
    );
  }

  Widget _kpiRing(
    BuildContext context,
    String label,
    String value, {
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final brand = theme.extension<AppBrandTheme>();
    final onBrandColor = brand?.onBrand ?? theme.colorScheme.onPrimary;
    return _circularBrandCard(
      context,
      semanticsLabel: '$label: $value',
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: onBrandColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: onBrandColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _powerliftingButton(BuildContext context, AppLocalizations loc) {
    final theme = Theme.of(context);
    final brand = theme.extension<AppBrandTheme>();
    final onBrandColor = brand?.onBrand ?? theme.colorScheme.onPrimary;

    elogUi('PROFILE_STATS_POWERLIFTING', {'title': loc.profileStatsPowerliftingButton});

    return _circularBrandCard(
      context,
      semanticsLabel: loc.profileStatsPowerliftingButton,
      onTap: () => Navigator.of(context).pushNamed(AppRouter.powerlifting),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fitness_center_rounded, color: onBrandColor, size: 28),
          const SizedBox(height: 8),
          Text(
            loc.profileStatsPowerliftingButton,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: onBrandColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _circularBrandCard(
    BuildContext context, {
    required Widget child,
    VoidCallback? onTap,
    String? semanticsLabel,
  }) {
    return Semantics(
      button: onTap != null,
      label: semanticsLabel,
      child: SizedBox(
        width: 112,
        height: 112,
        child: BrandGradientCard(
          borderRadius: BorderRadius.circular(56),
          padding: EdgeInsets.zero,
          onTap: onTap,
          child: Center(child: child),
        ),
      ),
    );
  }

  Future<void> _showFavoriteExercisesDialog(
    BuildContext context,
    ProfileProvider prov,
    AppLocalizations loc,
  ) async {
    final usages = prov.favoriteExerciseUsages;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(loc.profileStatsFavoriteExerciseDialogTitle),
          content: usages.isEmpty
              ? Text(loc.profileStatsFavoriteExerciseFallback)
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final usage in usages)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xs,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Expanded(
                              child: Text(
                                usage.name,
                                style: Theme.of(dialogContext)
                                    .textTheme
                                    .bodyMedium,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              loc.reportDeviceUsageSessions(
                                usage.sessionCount,
                              ),
                              style: Theme.of(dialogContext)
                                  .textTheme
                                  .bodyMedium,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                MaterialLocalizations.of(dialogContext).closeButtonLabel,
              ),
            ),
          ],
        );
      },
    );
  }
}

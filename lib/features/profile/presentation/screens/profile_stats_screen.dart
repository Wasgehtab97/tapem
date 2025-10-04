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

class _ProfileStatsScreenState extends State<ProfileStatsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = context.read<ProfileProvider>();
      if (!prov.isLoading && prov.trainingDates.isEmpty) {
        prov.loadTrainingDates(context);
      }
    });
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

    Widget buildContent() {
      if (prov.isLoading && totalTrainingDays == 0) {
        return const Center(child: CircularProgressIndicator());
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
        ],
      );
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
            child: buildContent(),
          ),
        ),
      ),
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

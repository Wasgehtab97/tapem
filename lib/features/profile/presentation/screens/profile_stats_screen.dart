import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart' as legacy_provider;

import 'package:tapem/app_router.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/core/providers/profile_provider.dart';
import 'package:tapem/features/rest_stats/providers/rest_stats_provider.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/widgets/brand_gradient_card.dart';
import 'package:tapem/core/logging/elog.dart';
import 'package:tapem/l10n/app_localizations.dart';

class ProfileStatsScreen extends ConsumerStatefulWidget {
  const ProfileStatsScreen({super.key});

  @override
  ConsumerState<ProfileStatsScreen> createState() => _ProfileStatsScreenState();
}

class _ProfileStatsScreenState extends ConsumerState<ProfileStatsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = legacy_provider.Provider.of<ProfileProvider>(
        context,
        listen: false,
      );
      if (!prov.isLoading && prov.trainingDates.isEmpty) {
        prov.loadTrainingDates(context);
      }
      final auth = ref.read(authViewStateProvider);
      final restStats = ref.read(restStatsProvider);
      final gymId = auth.gymCode;
      final userId = auth.userId;
      if (gymId != null && userId != null) {
        unawaited(
          restStats.load(gymId: gymId, userId: userId),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = legacy_provider.Provider.of<ProfileProvider>(context);
    final restStatsProv = ref.watch(restStatsProvider);
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
    final favoriteExercise = prov.favoriteExerciseName;
    final restValue = restStatsProv.isLoading &&
            restStatsProv.overallActualRestMs == null
        ? '…'
        : _formatRestDuration(restStatsProv.overallActualRestMs);

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
                loc.profileStatsRestTimerLabel,
                restValue,
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRouter.restStats),
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

  String _formatRestDuration(double? ms) {
    if (ms == null || ms.isNaN || ms.isInfinite) {
      return '—';
    }
    final duration = Duration(milliseconds: ms.round());
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).abs();
    final seconds = duration.inSeconds.remainder(60).abs();
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${duration.inMinutes}:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _kpiRing(
    BuildContext context,
    String label,
    String? value, {
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final brand = theme.extension<AppBrandTheme>();
    final onBrandColor = brand?.onBrand ?? theme.colorScheme.onPrimary;
    final trimmedValue = value?.trim();
    final hasValue = trimmedValue != null && trimmedValue.isNotEmpty;
    final displayValue = trimmedValue ?? '';
    final semanticsLabel = hasValue ? '$label: $displayValue' : label;
    return _circularBrandCard(
      context,
      semanticsLabel: semanticsLabel,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasValue) ...[
            Text(
              displayValue,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: onBrandColor,
              ),
            ),
            const SizedBox(height: 6),
          ],
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
    unawaited(prov.ensureFavoriteExercisesLoaded(context));

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Consumer<ProfileProvider>(
          builder: (context, provider, _) {
            final isLoading = provider.isFavoriteExercisesLoading;
            final error = provider.favoriteExercisesError;
            final usages = provider.favoriteExerciseUsages;

            Widget content;
            if (isLoading && usages.isEmpty && error == null) {
              content = const SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator()),
              );
            } else if (error != null) {
              content = Text(error);
            } else if (usages.isEmpty) {
              content = Text(loc.profileStatsFavoriteExerciseFallback);
            } else {
              content = Column(
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
              );
            }

            return AlertDialog(
              title: Text(loc.profileStatsFavoriteExerciseDialogTitle),
              content: content,
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
      },
    );
  }
}

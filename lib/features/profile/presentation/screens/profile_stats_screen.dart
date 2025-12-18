import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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
      final prov = ref.read(profileProvider);
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
    final prov = ref.watch(profileProvider);
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              loc.historyOverviewTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final gap = 12.0;

              // We'll use a custom layout or just a straightforward Column of Rows for better control
              // or a Wrap that mimics a grid.
              // Let's go with a custom Bento-ish layout using column/rows for the specific items we have.

              return Column(
                children: [
                   // Top Row: Total Days (Large) + Avg Days
                   Row(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Expanded(
                         flex: 3,
                         child: _StatCard(
                           label: loc.profileStatsTotalTrainingDays,
                           value: totalTrainingDays.toString(),
                           icon: Icons.calendar_today_rounded,
                           color: Colors.blueAccent,
                           isLarge: true,
                         ),
                       ),
                       SizedBox(width: gap),
                       Expanded(
                         flex: 4,
                         child: _StatCard(
                           label: loc.profileStatsAverageTrainingDaysPerWeek,
                           value: formatAverage(avgTrainingDays),
                           icon: Icons.show_chart_rounded,
                           color: Colors.purpleAccent,
                           subtitle: '/ ${loc.deviceLeaderboardTabWeek}',
                         ),
                       ),
                     ],
                   ),
                   SizedBox(height: gap),
                   // Second Row: Rest Timer + Favorite Exercise
                   Row(
                     children: [
                       Expanded(
                         child: _StatCard(
                           label: 'Rest Timer', // loc.profileStatsRestTimerLabel might be long, check localization
                           value: restValue,
                           icon: Icons.timer_outlined,
                           color: Colors.orangeAccent,
                           onTap: () => Navigator.of(context).pushNamed(AppRouter.restStats),
                         ),
                       ),
                       SizedBox(width: gap),
                       Expanded(
                         child: _StatCard(
                           label: 'Lieblingsübung', // loc.profileStatsFavoriteExercise
                           value: favoriteExercise,
                           icon: Icons.favorite_rounded,
                           color: Colors.pinkAccent,
                           onTap: () => _showFavoriteExercisesDialog(context, prov, loc),
                         ),
                       ),
                     ],
                   ),
                   SizedBox(height: gap),
                   // Bottom: Powerlifting (Full Width or special)
                   _StatCard(
                     label: loc.profileStatsPowerliftingButton,
                     value: 'Total & Wilks',
                     icon: Icons.fitness_center_rounded,
                     color: brandColor, // Theme color
                     onTap: () => Navigator.of(context).pushNamed(AppRouter.powerlifting),
                     isWide: true,
                   ),
                ],
              );
            },
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.profileStatsTitle,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
         decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.scaffoldBackgroundColor,
              Color.alphaBlend(brandColor.withOpacity(0.05), theme.scaffoldBackgroundColor),
            ],
          ),
        ),
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

  Future<void> _showFavoriteExercisesDialog(
    BuildContext context,
    ProfileProvider prov,
    AppLocalizations loc,
  ) async {
    // ... (keep existing dialog logic)
    unawaited(prov.ensureFavoriteExercisesLoaded(context));

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Consumer(
          builder: (context, ref, _) {
            final provider = ref.watch(profileProvider);
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

class _StatCard extends StatelessWidget {
  final String label;
  final String? value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool isLarge;
  final bool isWide;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.onTap,
    this.isLarge = false,
    this.isWide = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayValue = (value == null || value!.trim().isEmpty) ? '—' : value!;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          constraints: BoxConstraints(
            minHeight: isLarge ? 160 : 120, // Taller for large cards
          ),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
              width: 1,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.05),
                Colors.white.withOpacity(0.01),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Header with Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 20,
                      color: color,
                    ),
                  ),
                  if (onTap != null)
                     Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: Colors.white.withOpacity(0.3),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              // Content
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayValue,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: isLarge ? 32 : 24,
                      height: 1.1,
                      letterSpacing: -0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

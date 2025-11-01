import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../../core/theme/app_brand_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/community_stats.dart';
import '../../domain/models/feed_event.dart';
import '../providers/community_providers.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key, this.gymId});

  final String? gymId;

  @override
  Widget build(BuildContext context) {
    final resolvedGymId = gymId ?? context.read<AuthProvider>().gymCode ?? '';
    return riverpod.ProviderScope(
      overrides: [communityGymIdProvider.overrideWithValue(resolvedGymId)],
      child: const _CommunityScreenBody(),
    );
  }
}

class _CommunityScreenBody extends riverpod.ConsumerStatefulWidget {
  const _CommunityScreenBody();

  @override
  riverpod.ConsumerState<_CommunityScreenBody> createState() => _CommunityScreenBodyState();
}

class _CommunityScreenBodyState extends riverpod.ConsumerState<_CommunityScreenBody>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      return;
    }
    if (_tabIndex != _tabController.index) {
      setState(() {
        _tabIndex = _tabController.index;
      });
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
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
          tabs: [
            Tab(text: loc.communityTabToday),
            Tab(text: loc.communityTabWeek),
            Tab(text: loc.communityTabMonth),
          ],
          indicatorColor: brandColor,
          labelColor: brandColor,
          unselectedLabelColor:
              theme.colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          children: [
            _CommunityKpiSection(
              tabIndex: _tabIndex,
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: _CommunityFeedSection(
                highlightColor: brandColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommunityKpiSection extends riverpod.ConsumerWidget {
  const _CommunityKpiSection({required this.tabIndex});

  final int tabIndex;

  @override
  Widget build(BuildContext context, riverpod.WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final brandColor = brandTheme?.outline ?? theme.colorScheme.secondary;

    late final riverpod.AsyncValue<CommunityStats> statsValue;
    late final VoidCallback onRetry;

    switch (tabIndex) {
      case 1:
        statsValue = ref.watch(communityWeekProvider);
        onRetry = () => ref.refresh(communityWeekProvider);
        break;
      case 2:
        statsValue = ref.watch(communityMonthProvider);
        onRetry = () => ref.refresh(communityMonthProvider);
        break;
      case 0:
      default:
        statsValue = ref.watch(communityTodayProvider);
        onRetry = () => ref.refresh(communityTodayProvider);
        break;
    }

    final localeName = Localizations.localeOf(context).toLanguageTag();
    final numberFormat = NumberFormat.decimalPattern(localeName);
    final compactVolumeFormat = NumberFormat.decimalPatternDigits(
      locale: localeName,
      decimalDigits: 1,
    );

    Widget buildCards(CommunityStats stats) {
      final volume = stats.totalVolumeKg;
      final formattedVolume = volume % 1 == 0
          ? numberFormat.format(volume.round())
          : compactVolumeFormat.format(volume);
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

    Widget buildEmpty() {
      return _CommunityPlaceholder(
        message: loc.communityEmptyState,
      );
    }

    Widget buildError(Object error, StackTrace? stackTrace) {
      return _CommunityErrorState(
        message: loc.communityErrorState,
        onRetry: onRetry,
      );
    }

    return AnimatedSwitcher(
      duration: AppDurations.medium,
      child: statsValue.when(
        data: (stats) => stats.hasData ? buildCards(stats) : buildEmpty(),
        loading: () => const _CommunityKpiSkeleton(),
        error: buildError,
      ),
    );
  }
}

class _CommunityFeedSection extends riverpod.ConsumerWidget {
  const _CommunityFeedSection({required this.highlightColor});

  final Color highlightColor;

  @override
  Widget build(BuildContext context, riverpod.WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final feed = ref.watch(communityFeedProvider);
    final numberFormat = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final timeFormat = DateFormat.Hm(loc.localeName);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.cardLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.broadcast_on_home, color: highlightColor),
              const SizedBox(width: AppSpacing.xs),
              Text(
                loc.communityFeedTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: highlightColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: feed.when(
              data: (events) {
                if (events.isEmpty) {
                  return Center(
                    child: Text(
                      loc.communityFeedEmpty,
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return ListView.separated(
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
                  separatorBuilder: (_, __) => Divider(
                    color: theme.colorScheme.onSurface.withOpacity(0.05),
                  ),
                );
              },
              loading: () => const _CommunityFeedSkeleton(),
              error: (error, stackTrace) => _CommunityErrorState(
                message: loc.communityFeedError,
                onRetry: () => ref.refresh(communityFeedProvider),
              ),
            ),
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
    final background = theme.colorScheme.surfaceVariant;
    return Container(
      decoration: BoxDecoration(
        color: background.withOpacity(0.85),
        borderRadius: BorderRadius.circular(AppRadius.cardLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            backgroundColor: accentColor.withOpacity(0.12),
            foregroundColor: accentColor,
            child: Icon(icon),
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
    final name = event.displayName ?? loc.communityFeedAnonymous;
    final reps = numberFormat.format(event.reps);
    final volume = numberFormat.format(event.volumeKg.round());
    final created = event.createdAt != null
        ? timeFormat.format(event.createdAt!.toLocal())
        : '–';
    final parts = <String>[
      name,
      loc.communityFeedRepsLabel(reps),
      loc.communityFeedVolumeLabel(volume),
      created,
    ];
    if (event.deviceName != null && event.deviceName!.isNotEmpty) {
      parts.insert(1, event.deviceName!);
    }
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.bolt, color: highlightColor),
      title: Text(
        parts.join(' · '),
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onSurface,
        ),
      ),
      subtitle: event.funnyText == null || event.funnyText!.isEmpty
          ? null
          : Text(
              event.funnyText!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
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

class _CommunityErrorState extends StatelessWidget {
  const _CommunityErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final accent = brandTheme?.outline ?? theme.colorScheme.secondary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadius.cardLg),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: onRetry,
            child: Text(
              AppLocalizations.of(context)!.communityRetryButton,
              style: TextStyle(color: accent),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommunityKpiSkeleton extends StatelessWidget {
  const _CommunityKpiSkeleton();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        final placeholder = Container(
          height: 140,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
            borderRadius: BorderRadius.circular(AppRadius.cardLg),
          ),
        );
        if (isWide) {
          return Row(
            children: [
              for (var i = 0; i < 3; i++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: i == 2 ? 0 : AppSpacing.sm,
                    ),
                    child: placeholder,
                  ),
                ),
            ],
          );
        }
        return Column(
          children: [
            for (var i = 0; i < 3; i++)
              Padding(
                padding: EdgeInsets.only(
                  bottom: i == 2 ? 0 : AppSpacing.sm,
                ),
                child: placeholder,
              ),
          ],
        );
      },
    );
  }
}

class _CommunityFeedSkeleton extends StatelessWidget {
  const _CommunityFeedSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 6,
      itemBuilder: (_, index) {
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
      },
    );
  }
}

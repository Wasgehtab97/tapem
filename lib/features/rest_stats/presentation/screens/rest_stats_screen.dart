import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/features/rest_stats/providers/rest_stats_provider.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/widgets/brand_gradient_card.dart';
import 'package:tapem/features/rest_stats/domain/models/rest_stat_summary.dart';
import 'package:tapem/l10n/app_localizations.dart';

class RestStatsScreen extends ConsumerStatefulWidget {
  const RestStatsScreen({super.key});

  @override
  ConsumerState<RestStatsScreen> createState() => _RestStatsScreenState();
}

class _RestStatsScreenState extends ConsumerState<RestStatsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadStats());
  }

  Future<void> _loadStats({bool force = false}) async {
    final auth = ref.read(authViewStateProvider);
    final gymId = auth.gymCode;
    final userId = auth.userId;
    if (gymId == null || userId == null) {
      return;
    }
    await ref
        .read(restStatsProvider)
        .load(gymId: gymId, userId: userId, forceRefresh: force);
  }

  String _formatDuration(double? ms) {
    if (ms == null || ms.isNaN || ms.isInfinite) {
      return '—';
    }
    final duration = Duration(milliseconds: ms.round());
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).abs();
    final seconds = duration.inSeconds.remainder(60).abs();
    if (hours > 0) {
      final minStr = minutes.toString().padLeft(2, '0');
      final secStr = seconds.toString().padLeft(2, '0');
      return '$hours:$minStr:$secStr';
    }
    final minStr = minutes.toString().padLeft(2, '0');
    final secStr = seconds.toString().padLeft(2, '0');
    return '$minStr:$secStr';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final provider = ref.watch(restStatsProvider);
    final brand = theme.extension<AppBrandTheme>();
    final outlineColor = brand?.outline ?? theme.colorScheme.secondary;
    final actualMs = provider.overallActualRestMs;
    final totalSamples = provider.totalSampleCount;
    final totalSets = provider.totalSetCount;

    Widget buildHeroCard() {
      return BrandGradientCard(
        borderRadius: BorderRadius.circular(AppRadius.cardLg),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.restStatsHeadline,
              style: theme.textTheme.titleLarge?.copyWith(
                color: brand?.onBrand ?? theme.colorScheme.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _formatDuration(actualMs),
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: brand?.onBrand ?? theme.colorScheme.onPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              loc.restStatsHeroDescription,
              style: theme.textTheme.bodyMedium?.copyWith(
                color:
                    (brand?.onBrand ?? theme.colorScheme.onPrimary).withOpacity(0.84),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (totalSamples > 0 || totalSets > 0)
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.xs,
                children: [
                  if (totalSamples > 0)
                    Text(
                      loc.restStatsSampleCount(totalSamples),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: (brand?.onBrand ?? theme.colorScheme.onPrimary)
                            .withOpacity(0.9),
                      ),
                    ),
                  if (totalSets > 0)
                    Text(
                      loc.restStatsSetCount(totalSets),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: (brand?.onBrand ?? theme.colorScheme.onPrimary)
                            .withOpacity(0.9),
                      ),
                    ),
                ],
              ),
          ],
        ),
      );
    }

    Widget buildBody() {
      if (provider.isLoading && !provider.hasData) {
        return const Center(child: CircularProgressIndicator());
      }

      if (provider.error != null && !provider.hasData) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                loc.restStatsErrorMessage,
                style: theme.textTheme.bodyMedium?.copyWith(color: outlineColor),
              ),
              const SizedBox(height: AppSpacing.sm),
              FilledButton(
                onPressed: () => _loadStats(force: true),
                child: Text(loc.restStatsReloadCta),
              ),
            ],
          ),
        );
      }

      final items = provider.stats;
      return RefreshIndicator(
        onRefresh: () => _loadStats(force: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            buildHeroCard(),
            const SizedBox(height: AppSpacing.lg),
            if (provider.isLoading && provider.hasData)
              const LinearProgressIndicator(),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xl),
                child: Center(
                  child: Text(
                    loc.restStatsEmptyMessage,
                    style: theme.textTheme.bodyLarge?.copyWith(color: outlineColor),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            for (final stat in items) ...[
              _RestStatCard(
                stat: stat,
                formatter: _formatDuration,
                outlineColor: outlineColor,
                actualLabel: loc.restStatsActualLabel,
                sampleText: stat.sampleCount > 0
                    ? loc.restStatsSampleCount(stat.sampleCount)
                    : null,
                setCountLabel: stat.sumSetCount > 0
                    ? loc.restStatsSetCount(stat.sumSetCount)
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.restStatsTitle),
        centerTitle: true,
        foregroundColor: outlineColor,
      ),
      body: SafeArea(child: buildBody()),
    );
  }
}

class _RestStatCard extends StatelessWidget {
  const _RestStatCard({
    required this.stat,
    required this.formatter,
    required this.outlineColor,
    required this.actualLabel,
    this.sampleText,
    this.setCountLabel,
  });

  final RestStatSummary stat;
  final String Function(double? ms) formatter;
  final Color outlineColor;
  final String actualLabel;
  final String? sampleText;
  final String? setCountLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final average = stat.effectiveAverageActualRestMs;
    final title = stat.exerciseName?.isNotEmpty == true
        ? '${stat.deviceName} — ${stat.exerciseName}'
        : stat.deviceName;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      elevation: 0,
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: outlineColor,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '$actualLabel: ${formatter(average)}',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            if (sampleText != null || setCountLabel != null)
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  if (sampleText != null)
                    Text(
                      sampleText!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  if (setCountLabel != null)
                    Text(
                      setCountLabel!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

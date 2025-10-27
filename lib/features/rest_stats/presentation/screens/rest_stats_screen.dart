import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/rest_stats_provider.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/widgets/brand_gradient_card.dart';
import 'package:tapem/features/rest_stats/domain/models/rest_stat_summary.dart';
import 'package:tapem/l10n/app_localizations.dart';

class RestStatsScreen extends StatefulWidget {
  const RestStatsScreen({super.key});

  @override
  State<RestStatsScreen> createState() => _RestStatsScreenState();
}

class _RestStatsScreenState extends State<RestStatsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadStats());
  }

  Future<void> _loadStats({bool force = false}) async {
    final auth = context.read<AuthProvider>();
    final gymId = auth.gymCode;
    final userId = auth.userId;
    if (gymId == null || userId == null) {
      return;
    }
    await context
        .read<RestStatsProvider>()
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
    final provider = context.watch<RestStatsProvider>();
    final brand = theme.extension<AppBrandTheme>();
    final outlineColor = brand?.outline ?? theme.colorScheme.secondary;
    final plannedMs = provider.overallPlannedRestMs;
    final actualMs = provider.overallActualRestMs;
    final diffMs = provider.overallDifferenceMs;

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
              loc.restStatsHeroDescription,
              style: theme.textTheme.bodyMedium?.copyWith(
                color:
                    (brand?.onBrand ?? theme.colorScheme.onPrimary).withOpacity(0.84),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                _RestStatPill(
                  label: loc.restStatsActualLabel,
                  value: _formatDuration(actualMs),
                ),
                if (plannedMs != null) ...[
                  const SizedBox(width: AppSpacing.md),
                  _RestStatPill(
                    label: loc.restStatsPlannedLabel,
                    value: _formatDuration(plannedMs),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (diffMs != null)
              _DifferenceChip(
                diffMs: diffMs,
                formatter: _formatDuration,
              ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              loc.restStatsSampleCount(provider.totalSampleCount),
              style: theme.textTheme.labelMedium?.copyWith(
                color:
                    (brand?.onBrand ?? theme.colorScheme.onPrimary).withOpacity(0.9),
              ),
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
              _RestStatTile(
                stat: stat,
                formatter: _formatDuration,
                outlineColor: outlineColor,
                plannedLabel: loc.restStatsPlannedLabel,
                actualLabel: loc.restStatsActualLabel,
                sampleText: loc.restStatsSampleCount(stat.sampleCount),
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

class _RestStatPill extends StatelessWidget {
  const _RestStatPill({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onPrimaryContainer;
    final background = theme.colorScheme.primaryContainer.withOpacity(0.85);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(color: color),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DifferenceChip extends StatelessWidget {
  const _DifferenceChip({
    required this.diffMs,
    required this.formatter,
  });

  final double diffMs;
  final String Function(double? ms) formatter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPositive = diffMs > 0;
    final isNegative = diffMs < 0;
    final colorScheme = theme.colorScheme;
    Color background;
    Color foreground;
    if (isPositive) {
      background = colorScheme.errorContainer;
      foreground = colorScheme.onErrorContainer;
    } else if (isNegative) {
      background = colorScheme.secondaryContainer;
      foreground = colorScheme.onSecondaryContainer;
    } else {
      background = colorScheme.surfaceVariant;
      foreground = colorScheme.onSurfaceVariant;
    }

    final formatted = formatter(diffMs.abs());
    final prefix = diffMs > 0 ? '+' : diffMs < 0 ? '−' : '';
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Text(
        '${prefix.isEmpty ? '' : prefix}$formatted',
        style: theme.textTheme.labelMedium?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _RestStatTile extends StatelessWidget {
  const _RestStatTile({
    required this.stat,
    required this.formatter,
    required this.outlineColor,
    required this.plannedLabel,
    required this.actualLabel,
    required this.sampleText,
  });

  final RestStatSummary stat;
  final String Function(double? ms) formatter;
  final Color outlineColor;
  final String plannedLabel;
  final String actualLabel;
  final String sampleText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actual = stat.averageActualRestMs;
    final planned = stat.averagePlannedRestMs;
    final diff =
        actual != null && planned != null ? actual - planned : null;
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
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
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '$actualLabel: ${formatter(actual)}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (planned != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '$plannedLabel: ${formatter(planned)}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    sampleText,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  formatter(actual),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: outlineColor,
                  ),
                ),
                if (diff != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: _DifferenceChip(
                      diffMs: diff,
                      formatter: formatter,
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

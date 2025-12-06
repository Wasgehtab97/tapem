import 'package:flutter/material.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/features/report/domain/models/device_usage_stat.dart';
import 'package:tapem/core/providers/report_provider.dart';

class UsageKeyMetrics extends StatelessWidget {
  final List<DeviceUsageStat> stats;
  final DeviceUsageRange range;

  const UsageKeyMetrics({
    super.key,
    required this.stats,
    required this.range,
  });

  @override
  Widget build(BuildContext context) {
    final totalSessions = stats.fold<int>(0, (sum, item) => sum + item.sessions);
    
    final sortedStats = List<DeviceUsageStat>.from(stats)
      ..sort((a, b) => b.sessions.compareTo(a.sessions));
    final topDevice = sortedStats.isNotEmpty ? sortedStats.first : null;

    int days = 30;
    switch (range) {
      case DeviceUsageRange.last7Days:
        days = 7;
        break;
      case DeviceUsageRange.last30Days:
        days = 30;
        break;
      case DeviceUsageRange.last90Days:
        days = 90;
        break;
      case DeviceUsageRange.last365Days:
        days = 365;
        break;
      case DeviceUsageRange.all:
        days = 1; // Avoid division by zero, though "all" implies total history
        break;
    }
    
    // Simple average calculation
    final dailyAvg = (totalSessions / days).toStringAsFixed(1);

    return SizedBox(
      height: 110,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        children: [
          _MetricCard(
            label: 'Gesamt Sessions',
            value: '$totalSessions',
            icon: Icons.bar_chart_rounded,
            color: Colors.blue,
          ),
          const SizedBox(width: AppSpacing.md),
          _MetricCard(
            label: 'Top Gerät',
            value: topDevice?.name ?? '-',
            icon: Icons.emoji_events_rounded,
            color: Colors.amber,
            isTextValue: true,
          ),
          const SizedBox(width: AppSpacing.md),
          _MetricCard(
            label: 'Ø Sessions / Tag',
            value: dailyAvg,
            icon: Icons.timelapse_rounded,
            color: Colors.purple,
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isTextValue;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.isTextValue = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = theme.colorScheme.surface;
    final borderColor = theme.colorScheme.onSurface.withOpacity(0.05);

    return Container(
      width: 160,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: isTextValue && value.length > 10 ? 18 : 24,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

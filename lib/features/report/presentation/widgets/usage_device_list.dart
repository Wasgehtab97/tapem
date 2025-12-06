import 'package:flutter/material.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/widgets/premium_action_card.dart';
import 'package:tapem/features/report/domain/models/device_usage_stat.dart';

class UsageDeviceList extends StatelessWidget {
  final List<DeviceUsageStat> stats;

  const UsageDeviceList({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final sortedStats = List<DeviceUsageStat>.from(stats)
      ..sort((a, b) => b.sessions.compareTo(a.sessions));

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: sortedStats.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final stat = sortedStats[index];
        final rank = index + 1;
        
        return PremiumActionCard(
          title: stat.name,
          subtitle: '${stat.sessions} Sessions',
          leading: _RankBadge(rank: rank),
          showChevron: false, // No navigation for now, just info
          onTap: () {}, // Could open detailed device history later
        );
      },
    );
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;

  const _RankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTop3 = rank <= 3;
    
    Color color;
    if (rank == 1) {
      color = const Color(0xFFFFD700); // Gold
    } else if (rank == 2) {
      color = const Color(0xFFC0C0C0); // Silver
    } else if (rank == 3) {
      color = const Color(0xFFCD7F32); // Bronze
    } else {
      color = theme.colorScheme.onSurface.withOpacity(0.1);
    }

    final textColor = isTop3 ? Colors.black : theme.colorScheme.onSurface;

    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isTop3 ? color : Colors.transparent,
        shape: BoxShape.circle,
        border: isTop3 ? null : Border.all(color: color),
      ),
      child: Text(
        '$rank.',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}

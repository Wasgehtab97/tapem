import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/features/friends/domain/models/public_profile.dart';
import 'package:tapem/features/friends/presentation/widgets/friend_list_tile.dart';
import 'package:tapem/features/rank/domain/services/level_service.dart';

class DailyXpCard extends StatelessWidget {
  const DailyXpCard({
    super.key,
    required this.profile,
    required this.level,
    required this.xpInLevel,
    required this.totalXp,
    this.margin,
    this.padding = const EdgeInsets.all(AppSpacing.sm),
    this.gradient,
    this.numberFormat,
    this.footer,
    this.xpPerLevel = LevelService.xpPerLevel,
    this.maxLevel = LevelService.maxLevel,
  });

  final PublicProfile profile;
  final int level;
  final int xpInLevel;
  final int totalXp;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry padding;
  final Gradient? gradient;
  final NumberFormat? numberFormat;
  final Widget? footer;
  final int xpPerLevel;
  final int maxLevel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final gradientColors = gradient?.colors ??
        brandTheme?.gradient.colors ??
        AppGradients.brandGradient.colors;
    final highlightGradient = gradient ??
        brandTheme?.gradient ??
        AppGradients.brandGradient;
    final progressColor = gradientColors.first;
    final format = numberFormat ??
        NumberFormat.decimalPattern(Localizations.localeOf(context).toString());

    final xpLabel = '${format.format(xpInLevel)} / ${format.format(xpPerLevel)} XP';
    final totalXpLabel = 'Gesamt ${format.format(totalXp)} XP';
    final userProgress = level >= maxLevel ? 1.0 : xpInLevel / xpPerLevel;
    final xpRemaining = level >= maxLevel ? 0 : xpPerLevel - xpInLevel;
    final remainingText = level >= maxLevel
        ? 'Maximallevel erreicht'
        : '${format.format(xpRemaining)} XP bis Level ${level + 1}';

    final themed = theme.copyWith(
      textTheme: theme.textTheme.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      colorScheme: theme.colorScheme.copyWith(onSurface: Colors.white),
    );

    return Container(
      margin: margin ??
          const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
      decoration: BoxDecoration(
        gradient: highlightGradient,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Padding(
        padding: padding,
        child: Theme(
          data: themed,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              FriendListTile(
                profile: profile,
                subtitle: 'Level $level',
                trailing: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      xpLabel,
                      style: theme.textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ) ??
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      totalXpLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ) ??
                          const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: userProgress.clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: Colors.white.withOpacity(0.25),
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                remainingText,
                style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ) ??
                    const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              if (footer != null) ...[
                const SizedBox(height: AppSpacing.sm),
                footer!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

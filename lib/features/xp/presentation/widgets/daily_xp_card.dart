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
    this.onAvatarTap,
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
  final VoidCallback? onAvatarTap;

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

    // Better contrast: dark text on light gradient
    final textColor = Colors.black.withOpacity(0.85);
    final subtleTextColor = Colors.black.withOpacity(0.6);
    final progressBgColor = Colors.black.withOpacity(0.12);

    final themed = theme.copyWith(
      textTheme: theme.textTheme.apply(
        bodyColor: textColor,
        displayColor: textColor,
      ),
      colorScheme: theme.colorScheme.copyWith(onSurface: textColor),
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
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
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
                            color: textColor,
                            fontWeight: FontWeight.w700,
                          ) ??
                          TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    Text(
                      totalXpLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                            color: subtleTextColor,
                            fontWeight: FontWeight.w500,
                          ) ??
                          TextStyle(
                            color: subtleTextColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
                onAvatarTap: onAvatarTap,
              ),
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: userProgress.clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: progressBgColor,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progressColor.withOpacity(0.8),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                remainingText,
                style: theme.textTheme.bodySmall?.copyWith(
                      color: subtleTextColor,
                      fontWeight: FontWeight.w600,
                    ) ??
                    TextStyle(
                      color: subtleTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
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

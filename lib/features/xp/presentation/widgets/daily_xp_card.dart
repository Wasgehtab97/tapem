import 'package:flutter/material.dart';
import 'dart:math';

import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/features/avatars/domain/services/avatar_catalog.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/features/friends/domain/models/public_profile.dart';
import 'package:tapem/features/rank/domain/services/level_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DailyXpCard extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final gradientColors = gradient?.colors ??
        brandTheme?.gradient.colors ??
        AppGradients.brandGradient.colors;
    final format = numberFormat ??
        NumberFormat.decimalPattern(Localizations.localeOf(context).toString());

    final userProgress = level >= maxLevel ? 1.0 : xpInLevel / xpPerLevel;
    final xpRemaining = level >= maxLevel ? 0 : xpPerLevel - xpInLevel;
    final remainingText = level >= maxLevel
        ? 'Maximallevel erreicht'
        : '${format.format(xpRemaining)} XP bis Level ${level + 1}';

    final textColor = Colors.white.withOpacity(0.95);
    final subtleTextColor = Colors.white.withOpacity(0.7);
    final accent = gradientColors.last;
    final avatarKey = profile.avatarKey ?? 'default';
    final authView = ref.watch(authViewStateProvider);
    final currentGym = authView.gymCode;
    final avatarPath =
        AvatarCatalog.instance.resolvePathOrFallback(avatarKey, gymId: currentGym);

    final nameStyle = GoogleFonts.spaceGrotesk(
      textStyle: theme.textTheme.titleLarge,
      color: textColor,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
    );
    final subtitleStyle = GoogleFonts.spaceGrotesk(
      textStyle: theme.textTheme.bodyMedium,
      color: subtleTextColor,
      fontWeight: FontWeight.w600,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final roman = _toRoman(level);
        return Container(
      margin: margin ??
          const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(
                  gradientColors.first,
                  theme.colorScheme.surface,
                  0.25,
                ) ??
                gradientColors.first,
            Color.lerp(gradientColors.last, Colors.black, 0.35) ??
                gradientColors.last,
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.cardLg),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.45),
            blurRadius: 26,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Transform.rotate(
                angle: -pi / 10,
                child: Center(
                  child: SizedBox(
                    width: constraints.maxWidth * 0.9,
                    height: constraints.maxHeight * 0.8,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        roman,
                        style: GoogleFonts.cinzelDecorative(
                          fontSize: 220,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 6,
                          color: accent.withOpacity(0.32),
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                            Shadow(
                              color: accent.withOpacity(0.55),
                              blurRadius: 2,
                              offset: const Offset(0, 0),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: onAvatarTap,
                      child: Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1.4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            avatarPath,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(profile.username, style: nameStyle),
                          const SizedBox(height: 4),
                          Text(remainingText, style: subtitleStyle),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: userProgress.clamp(0.0, 1.0),
                    minHeight: 10,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      accent.withOpacity(0.85),
                    ),
                  ),
                ),
                if (footer != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  footer!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
      },
    );
  }
}

String _toRoman(int value) {
  if (value <= 0) return '';
  final numbers = [
    1000,
    900,
    500,
    400,
    100,
    90,
    50,
    40,
    10,
    9,
    5,
    4,
    1,
  ];
  final symbols = [
    'M',
    'CM',
    'D',
    'CD',
    'C',
    'XC',
    'L',
    'XL',
    'X',
    'IX',
    'V',
    'IV',
    'I',
  ];
  var remaining = value;
  final buffer = StringBuffer();
  for (var i = 0; i < numbers.length; i++) {
    while (remaining >= numbers[i]) {
      buffer.write(symbols[i]);
      remaining -= numbers[i];
    }
  }
  return buffer.toString();
}

import 'package:flutter/material.dart';
import 'dart:math';

import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/features/avatars/domain/services/avatar_catalog.dart';
import 'package:tapem/features/friends/data/friend_stats_repository.dart'; // Import FriendStats
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/features/friends/domain/models/public_profile.dart';
import 'package:tapem/features/friends/providers/friend_presence_provider.dart';
import 'package:tapem/features/rank/domain/services/level_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FriendXpCard extends ConsumerWidget {
  const FriendXpCard({
    super.key,
    required this.profile,
    required this.presence,
    required this.stats, // Added stats
    required this.onTap,
    this.onAvatarTap, // Added callback
    this.margin,
    this.padding = const EdgeInsets.all(AppSpacing.sm),
    this.gradient,
  });

  final PublicProfile profile;
  final PresenceState? presence;
  final FriendStats? stats; // Nullable to handle loading/error cases gracefully
  final VoidCallback onTap;
  final VoidCallback? onAvatarTap; // Optional callback
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry padding;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ... (rest of the build method setup remains the same) ...
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final gradientColors = gradient?.colors ??
        brandTheme?.gradient.colors ??
        AppGradients.brandGradient.colors;

    final textColor = Colors.white.withOpacity(0.95);
    final subtleTextColor = Colors.white.withOpacity(0.7);
    final accent = gradientColors.last;
    final avatarKey = profile.avatarKey ?? 'default';
    final authView = ref.watch(authViewStateProvider);
    final gymId = profile.primaryGymCode ?? authView.gymCode;

    final avatarPath =
        AvatarCatalog.instance.resolvePathOrFallback(avatarKey, gymId: gymId);
    
    // ... (rest of styles and logic) ...

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

    final isOnline = presence == PresenceState.workedOutToday;
    final statusText = isOnline ? 'Heute trainiert' : 'Offline';
    final statusColor = isOnline ? const Color(0xFF4CAF50) : Colors.grey[400];

    // Stats Logic
    final currentStats = stats ?? FriendStats.zero();
    final level = currentStats.level;
    final progress = currentStats.progress;
    
    // Formatting XP remaining
    final xpPerLevel = LevelService.xpPerLevel;
    final xpRemaining = xpPerLevel - currentStats.xpInLevel;
    final format = NumberFormat.decimalPattern(Localizations.localeOf(context).toString());
    
    // If user has leveled up at least once, show Roman numeral.
    final roman = _toRoman(level);

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTap: onTap,
          child: Container(
            margin: margin ?? const EdgeInsets.only(bottom: 12),
            clipBehavior: Clip.hardEdge, 
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
                // ... (Background stack logic) ...
                Positioned.fill(
                  child: IgnorePointer(
                    child: Transform.rotate(
                      angle: -pi / 10,
                      child: OverflowBox(
                        maxWidth: double.infinity,
                        maxHeight: double.infinity,
                        child: Center( 
                          child: Text(
                            roman,
                            style: GoogleFonts.cinzelDecorative(
                              fontSize: 100, 
                              fontWeight: FontWeight.w700,
                              letterSpacing: 6,
                              color: accent.withOpacity(0.15), 
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.25),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                                Shadow(
                                  color: accent.withOpacity(0.35),
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
                Padding(
                  padding: padding,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start, 
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          GestureDetector( // Added gesture detector for Avatar
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
                                  errorBuilder: (_, __, ___) => const Icon(Icons.person),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(profile.username, style: nameStyle),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    if (isOnline) ...[
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: statusColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                    ],
                                    Expanded(
                                      child: Text(
                                        // Combine Status and XP Text cleanly
                                        // E.g. "Online · 900 XP bis Level 6"
                                        // Or just "900 XP bis Level 6" and status is indicated by the dot?
                                        // User said: "only addition ... is offline/online marker".
                                        // Let's emulate the profile card subtitle "XP bis Level"
                                        // And prepend the status.
                                        level >= LevelService.maxLevel
                                            ? '$statusText · Max Level'
                                            : '$statusText · ${format.format(xpRemaining)} XP bis Lvl ${level + 1}',
                                        style: subtitleStyle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: Colors.white.withOpacity(0.5),
                            size: 24,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          minHeight: 10, // DailyXpCard uses 10 (from observing code or guessing premium thickness)
                          backgroundColor: Colors.white.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            accent.withOpacity(0.85),
                          ),
                        ),
                      ),
                      // Removed the bottom text as it is now in the subtitle
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

String _toRoman(int value) {
  if (value <= 0) return '';
  final numbers = [1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1];
  final symbols = ['M', 'CM', 'D', 'CD', 'C', 'XC', 'L', 'XL', 'X', 'IX', 'V', 'IV', 'I'];
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

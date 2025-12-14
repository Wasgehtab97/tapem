import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/xp_provider.dart';
import 'package:tapem/features/friends/domain/models/public_profile.dart';
import '../widgets/daily_xp_card.dart';
import '../widgets/xp_time_series_chart.dart';
import 'leaderboard_screen.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/widgets/brand_interactive_card.dart';

class DayXpScreen extends StatefulWidget {
  const DayXpScreen({Key? key}) : super(key: key);

  @override
  State<DayXpScreen> createState() => _DayXpScreenState();
}

class _DayXpScreenState extends State<DayXpScreen> {
  void _openLeaderboard() {
    final loc = AppLocalizations.of(context)!;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => LeaderboardScreen(
              title: loc.leaderboardTitle,
            ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      final xpProv = context.read<XpProvider>();
      final uid = auth.userId;
      if (uid != null) {
        xpProv.watchTrainingDays(uid);
        xpProv.watchStatsDailyXp(auth.gymCode ?? '', uid);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final xpProv = context.watch<XpProvider>();
    final auth = context.watch<AuthProvider>();
    final userLevel = xpProv.dailyLevel;
    final userXpInLevel = xpProv.dailyLevelXp;
    final locale = Localizations.localeOf(context).toString();
    final formatter = NumberFormat.decimalPattern(locale);

    Widget buildCurrentUserCard() {
      final profile = PublicProfile(
        uid: auth.userId ?? '',
        username: auth.userName ?? '',
        avatarKey: auth.avatarKey,
        primaryGymCode: auth.gymCode,
      );
      return DailyXpCard(
        profile: profile,
        level: userLevel,
        xpInLevel: userXpInLevel,
        totalXp: xpProv.statsDailyXp,
        numberFormat: formatter,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Erfahrung'),
      ),
      body: Padding(
        padding: const EdgeInsets.only(
          left: AppSpacing.sm,
          right: AppSpacing.sm,
          bottom: AppSpacing.lg,
        ),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.sm),
            buildCurrentUserCard(),
            const Spacer(),
            _LeaderboardCallToAction(onTap: _openLeaderboard),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardCallToAction extends StatelessWidget {
  const _LeaderboardCallToAction({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final radius =
        (brandTheme?.radius ?? BorderRadius.circular(AppRadius.card)) as BorderRadius;
    final onSurface = theme.colorScheme.onSurface;
    final brandColor = brandTheme?.outline ?? theme.colorScheme.secondary;
    final loc = AppLocalizations.of(context)!;

    return BrandInteractiveCard(
      onTap: onTap,
      borderRadius: radius,
      padding: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              brandColor.withOpacity(0.08),
              brandColor.withOpacity(0.02),
            ],
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(AppRadius.card),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: theme.colorScheme.onSurface.withOpacity(0.08),
                ),
              ),
              child: const Icon(
                Icons.leaderboard,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    loc.leaderboardTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    loc.profileStatsButtonSubtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: onSurface.withOpacity(0.6),
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    brandColor.withOpacity(0.22),
                    brandColor.withOpacity(0.02),
                  ],
                  center: Alignment.topLeft,
                  radius: 1.0,
                ),
                border: Border.all(
                  color: brandColor.withOpacity(0.4),
                  width: 1.1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_outward_rounded,
                color: brandColor,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

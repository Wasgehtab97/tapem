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
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard),
            tooltip: 'Rangliste',
            onPressed: _openLeaderboard,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        children: [
          const SizedBox(height: AppSpacing.sm),
          buildCurrentUserCard(),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/gym_provider.dart';
import '../../../../core/providers/xp_provider.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/widgets/brand_interactive_card.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'device_xp_leaderboard_screen.dart';

class DeviceXpScreen extends StatefulWidget {
  const DeviceXpScreen({Key? key}) : super(key: key);

  @override
  State<DeviceXpScreen> createState() => _DeviceXpScreenState();
}

class _DeviceXpScreenState extends State<DeviceXpScreen> {
  late final GymProvider _gymProv;
  late final XpProvider _xpProv;
  late final AuthProvider _auth;

  @override
  void initState() {
    super.initState();
    _gymProv = context.read<GymProvider>();
    _xpProv = context.read<XpProvider>();
    _auth = context.read<AuthProvider>();
    _gymProv.addListener(_syncWatchers);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncWatchers());
  }

  void _syncWatchers() {
    final uid = _auth.userId;
    final gymId = _gymProv.currentGymId;
    if (uid != null && gymId.isNotEmpty) {
      final deviceIds = _gymProv.devices.map((d) => d.uid).toList();
      _xpProv.watchDeviceXp(gymId, uid, deviceIds);
    }
  }

  @override
  void dispose() {
    _gymProv.removeListener(_syncWatchers);
    final uid = _auth.userId;
    final gymId = _gymProv.currentGymId;
    if (uid != null && gymId.isNotEmpty) {
      _xpProv.watchDeviceXp(gymId, uid, []);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final gymProv = context.watch<GymProvider>();
    final xpProv = context.watch<XpProvider>();
    final devices = gymProv.devices.toList();

    return Scaffold(
      appBar: AppBar(title: Text(loc.xpDeviceTitle)),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: devices.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (_, i) {
          final d = devices[i];
          final xp = xpProv.deviceXp[d.uid] ?? 0;
          return _DeviceXpCard(
            name: d.name,
            xp: xp,
            onTap: () {
              final gymId = gymProv.currentGymId;
              if (gymId.isEmpty) {
                return;
              }
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DeviceXpLeaderboardScreen(
                    gymId: gymId,
                    deviceId: d.uid,
                    deviceName: d.name,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _DeviceXpCard extends StatelessWidget {
  const _DeviceXpCard({
    required this.name,
    required this.xp,
    required this.onTap,
  });

  final String name;
  final int xp;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final brandColor = brandTheme?.outline ?? theme.colorScheme.secondary;

    return BrandInteractiveCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: brandColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
            child: Icon(
              Icons.fitness_center,
              color: brandColor,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$xp XP',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
        ],
      ),
    );
  }
}

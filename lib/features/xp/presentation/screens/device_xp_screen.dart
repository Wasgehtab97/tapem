import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/gym_provider.dart';
import '../../../../core/providers/xp_provider.dart';
import '../../../../core/logging/elog.dart';
import 'package:tapem/features/friends/domain/models/public_profile.dart';
import 'package:tapem/features/friends/presentation/widgets/friend_list_tile.dart';
import 'leaderboard_screen.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/widgets/brand_interactive_card.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';

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

  Future<void> _showLeaderboard(BuildContext context, String deviceId, String deviceName) async {
    elogDeviceXp('OPEN_LEADERBOARD', {'deviceId': deviceId});
    final fs = FirebaseFirestore.instance;
    final gymId = context.read<GymProvider>().currentGymId;
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final snap = await fs
          .collection('gyms')
          .doc(gymId)
          .collection('devices')
          .doc(deviceId)
          .collection('leaderboard')
          .where('showInLeaderboard', isEqualTo: true)
          .orderBy('xp', descending: true)
          .limit(5)
          .get();

      final entries = await Future.wait(
        snap.docs.map((doc) async {
          final user = await fs.collection('users').doc(doc.id).get();
          final profile = PublicProfile.fromMap(
              doc.id, user.data() ?? <String, dynamic>{});
          final xp = doc.data()['xp'] as int? ?? 0;
          return LeaderboardEntry(profile: profile, xp: xp);
        }),
      );

      if (!context.mounted) return;
      Navigator.of(context).pop(); // Close loading

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) => _LeaderboardSheet(
          deviceName: deviceName,
          entries: entries,
        ),
      );
    } catch (e) {
      if (context.mounted) Navigator.of(context).pop(); // Close loading on error
      debugPrint('Error loading leaderboard: $e');
    }
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
            onTap: () => _showLeaderboard(context, d.uid, d.name),
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

class _LeaderboardSheet extends StatelessWidget {
  const _LeaderboardSheet({
    required this.deviceName,
    required this.entries,
  });

  final String deviceName;
  final List<LeaderboardEntry> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.cardLg),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            deviceName,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(
                child: Text(
                  'Noch keine Einträge',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ),
            )
          else
            ...entries.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: FriendListTile(
                profile: e.value.profile,
                subtitle: '#${e.key + 1}',
                trailing: Text(
                  '${e.value.xp} XP',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            )),
        ],
      ),
    );
  }
}

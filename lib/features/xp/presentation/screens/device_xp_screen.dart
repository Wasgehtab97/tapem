import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/auth_providers.dart';
import '../../../../core/providers/xp_provider.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/widgets/brand_interactive_card.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'device_xp_leaderboard_screen.dart';

class DeviceXpScreen extends ConsumerStatefulWidget {
  const DeviceXpScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DeviceXpScreen> createState() => _DeviceXpScreenState();
}

enum _DeviceXpSort {
  xp,
  id,
}

class _DeviceXpScreenState extends ConsumerState<DeviceXpScreen> {
  String? _lastGymId;
  String? _lastUid;
  List<String> _lastDeviceIds = const [];
  _DeviceXpSort _sort = _DeviceXpSort.xp;

  void _syncWatchers(List<String> deviceIds) {
    final auth = ref.read(authViewStateProvider);
    final gymProv = ref.read(gymProvider);
    final xpProv = ref.read(xpProvider);

    final uid = auth.userId;
    final gymId = gymProv.currentGymId;
    if (uid == null || gymId.isEmpty) {
      return;
    }

    if (_lastGymId == gymId &&
        _lastUid == uid &&
        listEquals(_lastDeviceIds, deviceIds)) {
      return;
    }

    _lastGymId = gymId;
    _lastUid = uid;
    _lastDeviceIds = List.of(deviceIds);

    xpProv.watchDeviceXp(gymId, uid, deviceIds);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final gymProv = ref.watch(gymProvider);
    final xpProv = ref.watch(xpProvider);
    final devices = gymProv.devices.toList();
    final deviceIds = devices.map((d) => d.uid).toList();
    // Bei jedem Build sicherstellen, dass die Watcher korrekt gesetzt sind.
    _syncWatchers(deviceIds);

    devices.sort((a, b) {
      if (_sort == _DeviceXpSort.id) {
        return a.uid.compareTo(b.uid);
      }
      final xpA = xpProv.deviceXp[a.uid] ?? 0;
      final xpB = xpProv.deviceXp[b.uid] ?? 0;
      final byXp = xpB.compareTo(xpA);
      if (byXp != 0) {
        return byXp;
      }
      return a.uid.compareTo(b.uid);
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.xpDeviceTitle),
        actions: [
          PopupMenuButton<_DeviceXpSort>(
            icon: const Icon(Icons.sort),
            initialValue: _sort,
            onSelected: (value) {
              setState(() {
                _sort = value;
              });
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: _DeviceXpSort.xp,
                child: Text('XP'),
              ),
              PopupMenuItem(
                value: _DeviceXpSort.id,
                child: Text('ID'),
              ),
            ],
          ),
        ],
      ),
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

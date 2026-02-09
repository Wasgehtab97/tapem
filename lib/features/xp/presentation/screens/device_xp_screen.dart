import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/auth_providers.dart';
import '../../../../core/providers/xp_provider.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/widgets/brand_interactive_card.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/features/device/domain/models/device.dart';
import 'package:tapem/features/rank/domain/services/level_service.dart';
import 'package:tapem/features/rank/presentation/widgets/ranking_ui.dart';
import 'device_xp_leaderboard_screen.dart';

class DeviceXpScreen extends ConsumerStatefulWidget {
  const DeviceXpScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DeviceXpScreen> createState() => _DeviceXpScreenState();
}

enum _DeviceXpSort { xp, id }

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
    final totalXp = devices.fold<int>(
      0,
      (sum, device) => sum + (xpProv.deviceXp[device.uid] ?? 0),
    );
    final topDeviceName = devices.isEmpty ? '-' : devices.first.name;
    final nextLevelTarget = _resolveNextLevelTarget(
      devices: devices,
      xpByDevice: xpProv.deviceXp,
    );
    final isDe = Localizations.localeOf(
      context,
    ).languageCode.toLowerCase().startsWith('de');
    final locale = Localizations.localeOf(context).toString();
    final formatter = NumberFormat.decimalPattern(locale);

    return Scaffold(
      backgroundColor: const Color(0xFF0B1221),
      appBar: AppBar(
        title: Text(
          loc.xpDeviceTitle,
          style: GoogleFonts.orbitron(
            textStyle: Theme.of(context).textTheme.titleLarge,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
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
              PopupMenuItem(value: _DeviceXpSort.xp, child: Text('XP')),
              PopupMenuItem(value: _DeviceXpSort.id, child: Text('ID')),
            ],
          ),
        ],
      ),
      body: RankingGradientBackground(
        child: ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: devices.length + 2,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (_, i) {
            if (i == 0) {
              return _DeviceXpHero(
                deviceCount: devices.length,
                totalXp: totalXp,
                topDeviceName: topDeviceName,
              );
            }
            if (i == 1) {
              final title = isDe
                  ? 'Nächstes Device-Level in'
                  : 'Next device level in';
              final value = nextLevelTarget == null
                  ? 'Max'
                  : '${formatter.format(nextLevelTarget.xpToNextLevel)} XP';
              final subtitle = nextLevelTarget == null
                  ? (isDe
                        ? 'Alle Geräte sind auf Max-Level.'
                        : 'All devices are at max level.')
                  : (isDe
                        ? '${nextLevelTarget.deviceName} erreicht als Nächstes ein Level.'
                        : '${nextLevelTarget.deviceName} reaches the next level first.');
              return RankingGoalSignalCard(
                accent:
                    Theme.of(context).extension<AppBrandTheme>()?.outline ??
                    Theme.of(context).colorScheme.secondary,
                title: title,
                value: value,
                subtitle: subtitle,
                icon: Icons.rocket_launch_rounded,
              );
            }
            final device = devices[i - 2];
            final xp = xpProv.deviceXp[device.uid] ?? 0;
            return _DeviceXpCard(
              rank: i - 1,
              name: device.name,
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
                      deviceId: device.uid,
                      deviceName: device.name,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

_DeviceLevelTarget? _resolveNextLevelTarget({
  required List<Device> devices,
  required Map<String, int> xpByDevice,
}) {
  const xpPerLevel = LevelService.xpPerLevel;
  const maxLevel = LevelService.maxLevel;
  _DeviceLevelTarget? best;
  for (final device in devices) {
    final totalXp = xpByDevice[device.uid] ?? 0;
    var level = (totalXp ~/ xpPerLevel) + 1;
    if (level > maxLevel) {
      level = maxLevel;
    }
    if (level >= maxLevel) {
      continue;
    }
    final xpInLevel = totalXp % xpPerLevel;
    final xpToNext = xpPerLevel - xpInLevel;
    if (best == null || xpToNext < best.xpToNextLevel) {
      best = _DeviceLevelTarget(
        deviceName: device.name,
        xpToNextLevel: xpToNext,
      );
    }
  }
  return best;
}

class _DeviceLevelTarget {
  const _DeviceLevelTarget({
    required this.deviceName,
    required this.xpToNextLevel,
  });

  final String deviceName;
  final int xpToNextLevel;
}

class _DeviceXpCard extends StatelessWidget {
  const _DeviceXpCard({
    required this.rank,
    required this.name,
    required this.xp,
    required this.onTap,
  });

  final int rank;
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
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: brandColor.withOpacity(0.24)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surface.withOpacity(0.94),
              theme.colorScheme.surface.withOpacity(0.82),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.32),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: brandColor.withOpacity(0.13),
                borderRadius: BorderRadius.circular(AppRadius.button),
                border: Border.all(color: brandColor.withOpacity(0.38)),
              ),
              child: Center(
                child: Text(
                  '#$rank',
                  style: GoogleFonts.orbitron(
                    textStyle: theme.textTheme.titleSmall,
                    color: brandColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.rajdhani(
                      textStyle: theme.textTheme.titleMedium,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$xp XP',
                    style: GoogleFonts.orbitron(
                      textStyle: theme.textTheme.bodyMedium,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface.withOpacity(0.72),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeviceXpHero extends StatelessWidget {
  const _DeviceXpHero({
    required this.deviceCount,
    required this.totalXp,
    required this.topDeviceName,
  });

  final int deviceCount;
  final int totalXp;
  final String topDeviceName;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final formatter = NumberFormat.decimalPattern(locale);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF13243E), Color(0xFF1B355D), Color(0xFF264978)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.34),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _HeroTile(label: 'Geräte', value: '$deviceCount'),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _HeroTile(
              label: 'Gesamt XP',
              value: formatter.format(totalXp),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _HeroTile(label: 'Top Gerät', value: topDeviceName),
          ),
        ],
      ),
    );
  }
}

class _HeroTile extends StatelessWidget {
  const _HeroTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.rajdhani(
              textStyle: theme.textTheme.labelSmall,
              color: Colors.white.withOpacity(0.78),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.orbitron(
              textStyle: theme.textTheme.titleSmall,
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

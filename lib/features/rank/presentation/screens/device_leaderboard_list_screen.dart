import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:google_fonts/google_fonts.dart';

import 'package:tapem/app_router.dart';
import 'package:tapem/core/providers/gym_provider.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/features/rank/presentation/widgets/ranking_ui.dart';

class DeviceLeaderboardListScreen extends StatelessWidget {
  const DeviceLeaderboardListScreen({super.key, required this.gymId});

  final String gymId;

  @override
  Widget build(BuildContext context) {
    final container = riverpod.ProviderScope.containerOf(context);
    final gymProv = container.read(gymProvider);
    final devices = gymProv.devices.where((device) => !device.isMulti).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final accent = brandTheme?.outline ?? theme.colorScheme.secondary;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'Geraete-Rangliste',
          style: GoogleFonts.orbitron(
            textStyle: theme.textTheme.titleLarge,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ),
      body: RankingGradientBackground(
        child: ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: devices.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (_, index) {
            final device = devices[index];
            return Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.card),
                onTap: () {
                  Navigator.of(context).pushNamed(
                    AppRouter.rank,
                    arguments: {'gymId': gymId, 'deviceId': device.uid},
                  );
                },
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.surface.withOpacity(0.95),
                        theme.colorScheme.surface.withOpacity(0.84),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: accent.withOpacity(0.24)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.32),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(
                              AppRadius.button,
                            ),
                            border: Border.all(color: accent.withOpacity(0.4)),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: GoogleFonts.orbitron(
                                textStyle: theme.textTheme.titleSmall,
                                fontWeight: FontWeight.w700,
                                color: accent,
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
                                device.name,
                                style: GoogleFonts.rajdhani(
                                  textStyle: theme.textTheme.titleMedium,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'UID: ${device.uid}',
                                style: GoogleFonts.rajdhani(
                                  textStyle: theme.textTheme.bodySmall,
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.66),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, color: accent),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

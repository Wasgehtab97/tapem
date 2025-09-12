import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/workout_session_duration_service.dart';
import '../utils/duration_format.dart';
import '../providers/auth_provider.dart';
import '../providers/branding_provider.dart';

class WorkoutTimerButton extends StatelessWidget {
  const WorkoutTimerButton({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<WorkoutSessionDurationService>();
    final auth = context.read<AuthProvider>();
    final branding = context.read<BrandingProvider>();
    final uid = auth.userId;
    final gymId = branding.gymId;

    return Row(
      children: [
        if (service.isRunning)
          StreamBuilder<Duration>(
            stream: service.tickStream,
            initialData: service.elapsed,
            builder: (context, snap) {
              final d = snap.data ?? Duration.zero;
              final text = formatDuration(
                d,
                locale: Localizations.localeOf(context),
              );
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text('⏱ $text'),
              );
            },
          ),
        IconButton(
          tooltip: service.isRunning ? 'Training stoppen' : 'Training starten',
          icon: Icon(
            service.isRunning ? Icons.stop_circle : Icons.play_circle,
          ),
          onPressed: () async {
            if (service.isRunning) {
              final res = await service.confirmStop(context);
              if (res == StopResult.save) {
                await service.save();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Dauer gespeichert')),
                  );
                }
              } else if (res == StopResult.discard) {
                await service.discard();
              }
            } else {
              if (uid != null && gymId != null) {
                await service.start(uid: uid, gymId: gymId);
              }
            }
          },
        ),
      ],
    );
  }
}

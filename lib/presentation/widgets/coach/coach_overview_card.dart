// lib/presentation/widgets/coach/coach_overview_card.dart

import 'package:flutter/material.dart';
import 'package:tapem/domain/models/client_info.dart';

class CoachOverviewCard extends StatelessWidget {
  /// Die ClientInfo, die Name, ID und ggf. Beitrittsdatum enthält.
  final ClientInfo client;

  /// Wird aufgerufen, wenn die Karte angetippt wird.
  final VoidCallback? onTap;

  const CoachOverviewCard({
    Key? key,
    required this.client,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person, size: 48, color: Colors.white70),
            const SizedBox(height: 8),
            Text(
              client.name,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'ID: ${client.id}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white54,
              ),
            ),
            if (client.joinedAt != null) ...[
              const SizedBox(height: 4),
              Text(
                'Beigetreten: ${client.joinedAt!.toLocal().toString().split(' ')[0]}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white54,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

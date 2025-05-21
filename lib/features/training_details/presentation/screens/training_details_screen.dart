// lib/features/training_details/presentation/screens/training_details_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/training_details_provider.dart';
import 'package:tapem/features/training_details/domain/models/session.dart';

class TrainingDetailsScreen extends StatelessWidget {
  final DateTime date;

  const TrainingDetailsScreen({
    Key? key,
    required this.date,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();

    return ChangeNotifierProvider<TrainingDetailsProvider>(
      create: (_) {
        final prov = TrainingDetailsProvider();
        prov.loadSessions(
          userId: auth.userId!,
          date: date,
        );
        return prov;
      },
      child: Consumer<TrainingDetailsProvider>(
        builder: (ctx, prov, _) {
          // Loading state
          if (prov.isLoading) {
            return const Scaffold(
              appBar: _AppBar(titleDate: null),
              body: Center(child: CircularProgressIndicator()),
            );
          }
          // Error state
          if (prov.error != null) {
            return Scaffold(
              appBar: _AppBar(titleDate: date),
              body: Center(child: Text('Fehler: ${prov.error}')),
            );
          }
          // Data state
          final sessions = prov.sessions;
          return Scaffold(
            appBar: _AppBar(titleDate: date),
            body: sessions.isEmpty
                ? const Center(child: Text('Keine Trainingseinheiten'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: sessions.length,
                    itemBuilder: (_, i) => _SessionTile(
                      session: sessions[i],
                    ),
                  ),
          );
        },
      ),
    );
  }
}

/// Custom AppBar that shows `Training am <Datum>` or a placeholder title
class _AppBar extends StatelessWidget implements PreferredSizeWidget {
  final DateTime? titleDate;
  const _AppBar({this.titleDate});

  @override
  Widget build(BuildContext context) {
    final title = titleDate != null
        ? DateFormat.yMMMMd(
            Localizations.localeOf(context).toString(),
          ).format(titleDate!)
        : 'Training Details';

    return AppBar(title: Text('Training am $title'));
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Single session tile: deviceName (bold) + description underneath + all sets + optional note
class _SessionTile extends StatelessWidget {
  final Session session;
  const _SessionTile({required this.session});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ExpansionTile(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Device name in bold
            Text(
              session.deviceName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            // Device description, if available
            if (session.deviceDescription.isNotEmpty)
              Text(session.deviceDescription),
          ],
        ),
        // If you want the timestamp back, uncomment:
        // subtitle: Text(
        //   DateFormat.Hm(
        //     Localizations.localeOf(context).toString(),
        //   ).format(session.timestamp),
        // ),
        children: [
          // One ListTile per set
          ...session.sets.map(
            (s) => ListTile(
              title: Text('${s.weight} kg × ${s.reps} Wdh.'),
            ),
          ),
          // Optional note
          if (session.note.isNotEmpty) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text('Notiz: ${session.note}'),
            ),
          ],
        ],
      ),
    );
  }
}

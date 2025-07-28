// lib/features/training_details/presentation/screens/training_details_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/training_details_provider.dart';
import 'package:tapem/features/training_details/domain/models/session.dart';
import '../widgets/day_sessions_overview.dart';

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
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: sessions.isEmpty
                  ? const Center(child: Text('Keine Trainingseinheiten'))
                  : DaySessionsOverview(sessions: sessions),
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

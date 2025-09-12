// lib/features/training_details/presentation/screens/training_details_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:tapem/core/providers/training_details_provider.dart';
import 'package:tapem/core/providers/branding_provider.dart';
import 'package:tapem/features/training_details/domain/models/session.dart';
import '../widgets/day_sessions_overview.dart';
import 'package:tapem/core/utils/duration_format.dart';

class TrainingDetailsScreen extends StatelessWidget {
  final DateTime date;
  final String userId;

  const TrainingDetailsScreen({Key? key, required this.date, required this.userId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final gymId = context.read<BrandingProvider>().gymId!;
    return ChangeNotifierProvider<TrainingDetailsProvider>(
      create: (_) {
        final prov = TrainingDetailsProvider();
        prov.loadSessions(userId: userId, date: date, gymId: gymId);
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
          final duration = prov.dayDurationMs;
          return Scaffold(
            appBar: _AppBar(titleDate: date, durationMs: duration),
            body: sessions.isEmpty
                ? const Center(child: Text('Keine Trainingseinheiten'))
                : Scrollbar(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: DaySessionsOverview(sessions: sessions),
                    ),
                  ),
          );
        },
      ),
    );
  }
}

/// Custom AppBar that shows the selected date in the accent colour.
class _AppBar extends StatelessWidget implements PreferredSizeWidget {
  final DateTime? titleDate;
  final int? durationMs;
  const _AppBar({this.titleDate, this.durationMs});

  @override
  Widget build(BuildContext context) {
    final title =
        titleDate != null
            ? DateFormat.yMMMMd(
              Localizations.localeOf(context).toString(),
            ).format(titleDate!)
            : 'Training Details';

    Widget titleWidget = Text(
      title,
      style: TextStyle(color: Theme.of(context).colorScheme.secondary),
    );
    if (durationMs != null) {
      final dur = Duration(milliseconds: durationMs!);
      final formatted =
          formatDuration(dur, locale: Localizations.localeOf(context));
      titleWidget = Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(color: Theme.of(context).colorScheme.secondary),
          ),
          Text('⏱ $formatted'),
        ],
      );
    }
    return AppBar(title: titleWidget);
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

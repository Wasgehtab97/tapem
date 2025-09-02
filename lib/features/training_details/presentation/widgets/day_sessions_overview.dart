import 'package:flutter/material.dart';
import '../../domain/models/session.dart';
import 'session_exercise_card.dart';
import 'package:tapem/core/logging/elog.dart';

class DaySessionsOverview extends StatelessWidget {
  final List<Session> sessions;
  const DaySessionsOverview({Key? key, required this.sessions})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Limit to a maximum of two columns to avoid layout overflow on small screens
    final int columns = sessions.length <= 2 ? sessions.length : 2;
    return LayoutBuilder(
      builder: (context, constraints) {
        final double cardWidth =
            (constraints.maxWidth - (columns - 1) * 12) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: sessions
              .map(
                (session) {
                  elogUi('DETAILS_RENDER', {
                    'sessionId': session.sessionId,
                    'setNumbers':
                        session.sets.take(10).map((s) => s.setNumber).toList(),
                  });
                  return SizedBox(
                    width: cardWidth,
                    child: SessionExerciseCard(
                      title: session.deviceName,
                      subtitle: session.deviceDescription,
                      sets: session.sets,
                    ),
                  );
                },
              )
              .toList(),
        );
      },
    );
  }
}

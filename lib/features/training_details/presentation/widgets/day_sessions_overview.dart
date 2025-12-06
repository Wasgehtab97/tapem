import 'package:flutter/material.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import '../../domain/models/session.dart';
import 'training_session_item.dart';
import 'package:tapem/core/logging/elog.dart';

class DaySessionsOverview extends StatelessWidget {
  final List<Session> sessions;
  final void Function(Session session)? onSessionLongPress;

  const DaySessionsOverview({
    Key? key,
    required this.sessions,
    this.onSessionLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: sessions.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final session = sessions[index];
        elogUi('DETAILS_RENDER', {
          'sessionId': session.sessionId,
          'setNumbers': session.sets.take(10).map((s) => s.setNumber).toList(),
        });
        return TrainingSessionItem(
          session: session,
          index: index + 1,
          onLongPress: onSessionLongPress != null
              ? () => onSessionLongPress!(session)
              : null,
        );
      },
    );
  }
}

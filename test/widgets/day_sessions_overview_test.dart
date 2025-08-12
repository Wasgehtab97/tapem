import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/features/training_details/domain/models/session.dart';
import 'package:tapem/features/training_details/presentation/widgets/day_sessions_overview.dart';
import 'package:tapem/core/theme/design_tokens.dart';

void main() {
  testWidgets('Session card uses brand gradient', (tester) async {
    final session = Session(
      sessionId: 's1',
      deviceId: 'd1',
      deviceName: 'Device',
      deviceDescription: '',
      timestamp: DateTime.now(),
      note: '',
      sets: [SessionSet(weight: 10, reps: 5)],
    );

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData.dark(),
      home: DaySessionsOverview(sessions: [session]),
    ));

    final container = tester.widget<Container>(
      find.descendant(
        of: find.byType(DaySessionsOverview),
        matching: find.byType(Container),
      ).first,
    );
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.gradient, AppGradients.brandGradient);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/features/training_details/domain/models/session.dart';
import 'package:tapem/features/training_details/presentation/widgets/cardio_session_card.dart';

void main() {
  testWidgets('renders timed cardio session', (tester) async {
    final session = Session(
      sessionId: 's1',
      deviceId: 'c1',
      deviceName: 'Treadmill',
      deviceDescription: '',
      timestamp: DateTime.now(),
      note: '',
      sets: const [],
      isCardio: true,
      mode: 'timed',
      durationSec: 60,
    );
    await tester.pumpWidget(MaterialApp(home: CardioSessionCard(session: session)));
    expect(find.textContaining('Zeit'), findsOneWidget);
  });
}

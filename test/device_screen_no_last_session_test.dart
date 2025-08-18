import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/core/config/feature_flags.dart';
import 'package:tapem/features/device/presentation/widgets/last_session_card.dart';

void main() {
  testWidgets('hides last session when flag is false', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              if (FF.isLastSessionVisible) ...[
                const SizedBox(height: 16),
                LastSessionCard(
                  date: DateTime(2000),
                  sets: const [],
                  note: null,
                ),
                const SizedBox(height: 12),
              ]
            ],
          ),
        ),
      ),
    );

    expect(find.byType(LastSessionCard), findsNothing);
    expect(find.text('Letzte Session'), findsNothing);
  });
}

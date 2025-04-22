// lib/screens/dashboard.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/feedback_form.dart';
import 'dashboard/dashboard_controller.dart';
import 'dashboard/input_table.dart';
import 'dashboard/multi_exercise_selector.dart';
import 'dashboard/last_session_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Argumente aus der Navigator-Route holen
    final args = ModalRoute.of(context)?.settings.arguments;
    String deviceIdArg = '';
    String? secretCodeArg;
    if (args is Map<String, dynamic>) {
      deviceIdArg = args['deviceId']?.toString() ?? '';
      secretCodeArg = args['secretCode']?.toString();
    }

    return ChangeNotifierProvider<DashboardController>(
      create: (_) =>
          DashboardController()..loadDevice(deviceIdArg, secretCode: secretCodeArg),
      child: Consumer<DashboardController>(
        builder: (ctx, ctrl, _) {
          final theme = Theme.of(ctx);
          final date = ctrl.trainingDate;

          // Deutsches Array mit Wochentagsnamen
          const weekdays = [
            'Montag',
            'Dienstag',
            'Mittwoch',
            'Donnerstag',
            'Freitag',
            'Samstag',
            'Sonntag',
          ];
          final weekday = weekdays[date.weekday - 1];

          // Datum manuell DD.MM.YYYY formatieren
          final formattedDate =
              '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';

          return Scaffold(
            appBar: AppBar(
              title: Text(
                ctrl.selectedExercise != null
                    ? "${ctrl.selectedExercise} – ${ctrl.deviceInfo?['name'] ?? 'Gerät ${ctrl.deviceId}'}"
                    : ctrl.deviceInfo?['name'] ?? "Gerät ${ctrl.deviceId}",
              ),
            ),
            body: ctrl.isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Anzeige: "Dienstag, 22.04.2025"
                        Text(
                          "$weekday, $formattedDate",
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),

                        // Multi-Mode: Übungsauswahl, sonst Eingabetabelle
                        if (ctrl.deviceInfo != null &&
                            ctrl.deviceInfo!['exercise_mode']
                                    .toString()
                                    .toLowerCase() !=
                                'single' &&
                            ctrl.selectedExercise == null)
                          const MultiExerciseSelector()
                        else
                          const InputTable(),

                        const SizedBox(height: 16),

                        // Buttons: Nächster Satz & Fertig
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: ctrl.addSet,
                              child: const Text("Nächster Satz"),
                            ),
                            ElevatedButton(
                              onPressed: ctrl.finishSession,
                              child: const Text("Fertig"),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Letzte Session + Link zur Historie (nur wenn Exercise gewählt)
                        if (ctrl.selectedExercise != null) ...[
                          const LastSessionCard(),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                '/history',
                                arguments: {
                                  'deviceId': ctrl.deviceId!,
                                  'exercise': ctrl.selectedExercise!,
                                },
                              );
                            },
                            child: const Text("Zur Trainingshistorie"),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Feedback-Formular
                        ElevatedButton(
                          onPressed: ctrl.toggleFeedback,
                          child: Text(ctrl.showFeedback
                              ? "Feedback schließen"
                              : "Feedback geben"),
                        ),
                        if (ctrl.showFeedback)
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: FeedbackForm(
                              deviceId:
                                  int.tryParse(ctrl.deviceId ?? '') ?? 0,
                              onClose: ctrl.toggleFeedback,
                              onFeedbackSubmitted: (_) {},
                            ),
                          ),
                      ],
                    ),
                  ),
            bottomNavigationBar: Container(
              height: 50,
              color: theme.primaryColor,
            ),
          );
        },
      ),
    );
  }
}

// lib/screens/dashboard/last_session_card.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dashboard_controller.dart';

class LastSessionCard extends StatelessWidget {
  const LastSessionCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<DashboardController>();
    final session = ctrl.lastSession;
    final theme = Theme.of(context);
    final headerBg = theme.colorScheme.secondaryContainer;
    final headerFg = theme.colorScheme.onSecondaryContainer;
    final cellFg = theme.colorScheme.onSurface;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(vertical: 12),
      color: theme.colorScheme.surfaceVariant,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Letzte Trainingseinheit",
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 8),
            if (session != null)
              Text(
                "Datum: ${ctrl.trainingDate.toIso8601String().split('T').first}",
                style: theme.textTheme.bodyMedium,
              )
            else
              Text(
                "Keine Daten vorhanden.",
                style: theme.textTheme.bodyMedium,
              ),
            const SizedBox(height: 16),
            if (session != null)
              LayoutBuilder(
                builder: (context, constraints) {
                  // Jede der drei Spalten nimmt ein Drittel der Breite minus etwas Padding
                  final colWidth = (constraints.maxWidth - 16) / 3;
                  return Column(
                    children: [
                      // Header
                      Row(
                        children: [
                          _buildCell("Satz", headerBg, headerFg, colWidth),
                          _buildCell("Kg", headerBg, headerFg, colWidth),
                          _buildCell("Wdh", headerBg, headerFg, colWidth),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Datenreihen
                      for (var s in session.sets) ...[
                        Row(
                          children: [
                            _buildCell(s.setNumber.toString(), Colors.transparent, cellFg, colWidth),
                            _buildCell(s.weight, Colors.transparent, cellFg, colWidth),
                            _buildCell(s.reps.toString(), Colors.transparent, cellFg, colWidth),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCell(String text, Color bg, Color fg, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: bg == Colors.transparent
            ? null
            : const BorderRadius.vertical(top: Radius.circular(4)),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: bg == Colors.transparent ? FontWeight.normal : FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }
}

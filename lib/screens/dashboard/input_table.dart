import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dashboard_controller.dart';

class InputTable extends StatelessWidget {
  const InputTable({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<DashboardController>();
    final theme = Theme.of(context);
    final headerBg = theme.colorScheme.secondaryContainer;
    final headerFg = theme.colorScheme.onSecondaryContainer;

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.symmetric(vertical: 12),
      color: theme.colorScheme.surfaceVariant,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Table(
          columnWidths: const {
            0: FixedColumnWidth(40),
            1: FixedColumnWidth(60),
            2: FixedColumnWidth(60),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            // Header mit dunklem Hintergrund
            TableRow(
              decoration: BoxDecoration(
                color: headerBg,
                borderRadius: BorderRadius.circular(8),
              ),
              children: [
                _header("Satz", headerFg),
                _header("Kg", headerFg),
                _header("Wdh", headerFg),
              ],
            ),
            // Eingabezeilen
            ...List.generate(ctrl.sets.length, (i) {
              final s = ctrl.sets[i];
              final weightCtrl = TextEditingController(text: s.weight);
              final repsCtrl = TextEditingController(
                  text: s.reps > 0 ? s.reps.toString() : '');
              return TableRow(children: [
                Center(
                  child: Text(
                    s.setNumber.toString(),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: TextField(
                    controller: weightCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => ctrl.updateSet(i, weight: v),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: TextField(
                    controller: repsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) =>
                        ctrl.updateSet(i, reps: int.tryParse(v) ?? 0),
                  ),
                ),
              ]);
            }),
          ],
        ),
      ),
    );
  }

  Widget _header(String text, Color fg) => Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: fg,
          ),
        ),
      );
}

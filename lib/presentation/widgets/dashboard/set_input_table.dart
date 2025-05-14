// lib/presentation/widgets/dashboard/set_input_table.dart

import 'package:flutter/material.dart';

/// Allgemeine Tabelle für freie Set-Eingaben (z.B. Satz, Kg, Wdh).
class SetInputTable extends StatelessWidget {
  final List<Map<String, dynamic>> rawSets;
  final List<TextEditingController> weightCtrls;
  final List<TextEditingController> repsCtrls;
  final void Function(int index, String field, String value) onChange;

  const SetInputTable({
    Key? key,
    required this.rawSets,
    required this.weightCtrls,
    required this.repsCtrls,
    required this.onChange,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
            TableRow(
              decoration: BoxDecoration(color: Colors.grey[300]),
              children: const [
                Center(child: Text('Satz')),
                Center(child: Text('Kg')),
                Center(child: Text('Wdh')),
              ],
            ),
            for (var i = 0; i < rawSets.length; i++)
              TableRow(
                children: [
                  Center(
                      child:
                          Text(rawSets[i]['setNumber'].toString())),
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: TextField(
                      controller: weightCtrls[i],
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          isDense: true, border: OutlineInputBorder()),
                      onChanged: (v) => onChange(i, 'weight', v),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: TextField(
                      controller: repsCtrls[i],
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          isDense: true, border: OutlineInputBorder()),
                      onChanged: (v) => onChange(i, 'reps', v),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

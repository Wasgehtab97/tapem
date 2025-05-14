import 'package:flutter/material.dart';

class ExerciseSelector extends StatelessWidget {
  final List<String> options;
  final String? selected;
  final ValueChanged<String> onSelect;
  final VoidCallback onAddCustom;

  const ExerciseSelector({
    Key? key,
    required this.options,
    this.selected,
    required this.onSelect,
    required this.onAddCustom,
  }) : super(key: key);

  @override
  Widget build(BuildContext c) {
    return Column(
      children: [
        ...options.map((o) => ListTile(
              title: Text(o),
              selected: o == selected,
              onTap: () => onSelect(o),
            )),
        TextButton.icon(
          icon: Icon(Icons.add),
          label: Text('Eigenes hinzufügen'),
          onPressed: onAddCustom,
        ),
      ],
    );
  }
}

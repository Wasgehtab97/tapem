import 'package:flutter/material.dart';

class MuscleGroupCard extends StatelessWidget {
  final String name;
  final bool selected;
  final bool primary;
  final VoidCallback onTap;

  const MuscleGroupCard({
    Key? key,
    required this.name,
    required this.selected,
    required this.primary,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color bgColor =
        selected
            ? (primary
                ? theme.colorScheme.primary
                : theme.colorScheme.secondary)
            : theme.colorScheme.surface;
    final Color textColor =
        selected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(name, style: TextStyle(color: textColor)),
      ),
    );
  }
}

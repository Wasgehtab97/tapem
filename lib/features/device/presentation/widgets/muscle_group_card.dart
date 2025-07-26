import 'package:flutter/material.dart';

class MuscleGroupCard extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isPrimary;
  final VoidCallback onTap;

  const MuscleGroupCard({
    super.key,
    required this.label,
    required this.selected,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = selected
        ? (isPrimary ? scheme.primary : scheme.secondary)
        : scheme.surfaceVariant;
    final textColor = selected ? scheme.onPrimary : scheme.onSurface;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            label,
            style: TextStyle(color: textColor),
          ),
        ),
      ),
    );
  }
}

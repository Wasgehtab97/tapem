import 'package:flutter/material.dart';
import 'package:tapem/features/muscle_group/domain/models/muscle_group.dart';

Color colorForRegion(MuscleRegion region, ThemeData theme) {
  switch (region.category) {
    case MuscleCategory.upperFront:
      return Colors.red.shade300;
    case MuscleCategory.upperBack:
      return Colors.blue.shade300;
    case MuscleCategory.core:
      return Colors.purple.shade300;
    case MuscleCategory.lower:
      return Colors.teal.shade300;
  }
}

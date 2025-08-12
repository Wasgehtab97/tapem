import 'package:flutter/material.dart';
import 'package:tapem/features/muscle_group/domain/models/muscle_group.dart';

Color colorForRegion(MuscleRegion region, ThemeData theme) {
  switch (region.category) {
    case MuscleCategory.upperFront:
    case MuscleCategory.core:
      return theme.colorScheme.primary;
    case MuscleCategory.upperBack:
    case MuscleCategory.lower:
      return theme.colorScheme.secondary;
  }
}

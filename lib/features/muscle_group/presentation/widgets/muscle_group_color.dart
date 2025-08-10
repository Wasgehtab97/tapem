import 'package:flutter/material.dart';
import '../../domain/models/muscle_group.dart';

Color colorForRegion(MuscleRegion region, ThemeData theme) {
  switch (region) {
    case MuscleRegion.chest:
      return Colors.red.shade300;
    case MuscleRegion.back:
      return Colors.blue.shade300;
    case MuscleRegion.shoulders:
      return Colors.orange.shade300;
    case MuscleRegion.arms:
      return Colors.green.shade300;
    case MuscleRegion.core:
      return Colors.purple.shade300;
    case MuscleRegion.legs:
      return Colors.teal.shade300;
  }
}

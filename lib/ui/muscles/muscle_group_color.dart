import 'package:flutter/material.dart';
import 'package:tapem/features/muscle_group/domain/models/muscle_group.dart';

Color colorForRegion(MuscleRegion region) {
  switch (region) {
    case MuscleRegion.chest:
      return Colors.red;
    case MuscleRegion.anteriorDeltoid:
    case MuscleRegion.posteriorDeltoid:
    case MuscleRegion.upperTrapezius:
      return Colors.orange;
    case MuscleRegion.biceps:
    case MuscleRegion.triceps:
    case MuscleRegion.wristFlexors:
      return Colors.blue;
    case MuscleRegion.lats:
    case MuscleRegion.midBack:
      return Colors.green;
    case MuscleRegion.rectusAbdominis:
    case MuscleRegion.obliques:
    case MuscleRegion.transversusAbdominis:
      return Colors.purple;
    case MuscleRegion.quadriceps:
    case MuscleRegion.hamstrings:
    case MuscleRegion.glutes:
    case MuscleRegion.adductors:
    case MuscleRegion.abductors:
    case MuscleRegion.calves:
    case MuscleRegion.tibialisAnterior:
      return Colors.brown;
  }
}

import 'package:flutter/material.dart';
import 'package:tapem/features/muscle_group/domain/models/muscle_group.dart';

Color colorForRegion(MuscleRegion region) {
  switch (region) {
    case MuscleRegion.brust:
      return Colors.red;
    case MuscleRegion.schulter:
      return Colors.orange;
    case MuscleRegion.nacken:
      return Colors.deepOrange;
    case MuscleRegion.ruecken:
      return Colors.green;
    case MuscleRegion.bizeps:
      return Colors.blue;
    case MuscleRegion.trizeps:
      return Colors.indigo;
    case MuscleRegion.bauch:
      return Colors.purple;
    case MuscleRegion.quadrizeps:
    case MuscleRegion.hamstrings:
    case MuscleRegion.gluteus:
    case MuscleRegion.waden:
      return Colors.brown;
  }
}

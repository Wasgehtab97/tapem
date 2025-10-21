import 'package:flutter/material.dart';

import '../../../muscle_group/presentation/screens/muscle_group_screen_new.dart';

/// Displays the muscle group overview inside the XP section.
///
/// The XP overview previously contained a bespoke dashboard, but the
/// application now reuses the dedicated muscle group screen to present the
/// exact same radar chart and detail list. Wrapping the existing screen keeps
/// behaviour aligned while avoiding duplicated UI code.
class XpOverviewScreen extends StatelessWidget {
  const XpOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MuscleGroupScreenNew();
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'report_screen_new.dart';
import 'package:tapem/core/providers/gym_provider.dart';

class ReportScreen extends StatelessWidget {
  static const routeName = '/report';
  const ReportScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final gymId = context.watch<GymProvider>().currentGymId;
    // Using UniqueKey to force rebuild and ensure new UI is picked up
    return ReportScreenNew(key: UniqueKey(), gymId: gymId);
  }
}

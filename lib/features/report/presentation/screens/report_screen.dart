import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;

import 'report_screen_new.dart';
import 'package:tapem/core/providers/auth_providers.dart';

class ReportScreen extends StatelessWidget {
  static const routeName = '/report';
  const ReportScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final container = riverpod.ProviderScope.containerOf(context);
    final gymId = container.read(authViewStateProvider).gymCode ?? '';
    return ReportScreenNew(gymId: gymId);
  }
}

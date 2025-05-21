// lib/features/report/presentation/screens/report_dashboard_screen.dart
import 'package:flutter/material.dart';

class ReportDashboardScreen extends StatelessWidget {
  const ReportDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report')),
      body: const Center(child: Text('Report-Dashboard hier')),
    );
  }
}

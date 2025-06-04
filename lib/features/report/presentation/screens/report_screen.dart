// lib/features/report/presentation/screens/report_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/gym_provider.dart';
import 'package:tapem/core/providers/report_provider.dart';
import '../widgets/device_usage_chart.dart';
import '../widgets/calendar_heatmap.dart';
import 'package:tapem/features/device/domain/models/device.dart';


class ReportScreen extends StatelessWidget {
  static const routeName = '/report';
  const ReportScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final reportProv = context.watch<ReportProvider>();
    // Holen der gymId und der Geräte-Liste aus dem GymProvider
    final gymProv = context.read<GymProvider>();
    final gymId = gymProv.currentGymId;
    final devices = gymProv.devices;

    return Scaffold(
      appBar: AppBar(title: const Text('Studio Report')),
      body: RefreshIndicator(
        onRefresh: () => reportProv.loadReport(gymId),
        child: _buildContent(reportProv, gymId, devices),
      ),
    );
  }

  Widget _buildContent(
      ReportProvider prov, String gymId, List<Device> devices) {
    if (prov.state == ReportState.initial) {
      prov.loadReport(gymId);
    }
    switch (prov.state) {
      case ReportState.loading:
        return const Center(child: CircularProgressIndicator());
      case ReportState.error:
        return Center(child: Text('Fehler: ${prov.errorMessage}'));
      case ReportState.loaded:
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Geräte-Nutzung',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: DeviceUsageChart(
                devices: devices,
                usageCounts: prov.usageCounts,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Trainings-Heatmap',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            CalendarHeatmap(dates: prov.heatmapDates),
          ],
        );
      default:
        return const Center(child: Text('Ziehe nach unten, um zu laden'));
    }
  }
}

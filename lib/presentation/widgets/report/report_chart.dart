// lib/presentation/widgets/report/report_chart.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:tapem/domain/models/report_entry.dart';
import 'package:tapem/domain/repositories/tenant_repository.dart';
import 'package:tapem/domain/repositories/report_repository.dart';
import 'package:tapem/presentation/widgets/common/loading_indicator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Zeigt eine Kuchen-Chart der Sitzungen im Gym für den optionalen Zeitraum.
class ReportChart extends StatelessWidget {
  /// Optionaler Zeitraum-Filter.
  final DateTime? start;
  final DateTime? end;

  const ReportChart({
    Key? key,
    this.start,
    this.end,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tenantRepo = context.read<TenantRepository>();
    final reportRepo = context.read<ReportRepository>();

    final gymId = tenantRepo.gymId;
    if (gymId == null || gymId.isEmpty) {
      return const Center(child: Text('Kein Gym ausgewählt'));
    }

    return FutureBuilder<List<ReportEntry>>(
      future: reportRepo.fetchReportData(
        gymId: gymId,
        start: start,
        end: end,
      ),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const LoadingIndicator();
        }
        if (snap.hasError) {
          return Center(child: Text('Fehler: ${snap.error}'));
        }
        final data = snap.data ?? [];
        if (data.isEmpty) {
          return const Center(child: Text('Keine Daten für den Zeitraum.'));
        }

        // Chart-Abschnitte erzeugen (alle in der Primärfarbe)
        final sections = data.map((entry) {
          return PieChartSectionData(
            value: entry.sessionCount.toDouble(),
            color: Theme.of(context).colorScheme.primary,
            title: '${entry.sessionCount}',
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList();

        return PieChart(
          PieChartData(
            sections: sections,
            sectionsSpace: 2,
            centerSpaceRadius: 40,
            borderData: FlBorderData(show: false),
          ),
        );
      },
    );
  }
}

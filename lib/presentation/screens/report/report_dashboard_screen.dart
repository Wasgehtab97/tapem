// lib/presentation/screens/report/report_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tapem/presentation/blocs/report/report_bloc.dart';
import 'package:tapem/presentation/blocs/report/report_event.dart';
import 'package:tapem/presentation/blocs/report/report_state.dart';
import 'package:tapem/presentation/widgets/report/report_chart.dart';
import 'package:tapem/presentation/widgets/common/loading_indicator.dart';
import 'package:tapem/domain/models/device_info.dart';
import 'package:tapem/domain/usecases/report/fetch_devices.dart';
import 'package:tapem/domain/usecases/report/fetch_report_data.dart';
import 'package:tapem/domain/usecases/tenant/get_saved_gym_id.dart';

class ReportDashboardScreen extends StatefulWidget {
  const ReportDashboardScreen({Key? key}) : super(key: key);

  @override
  State<ReportDashboardScreen> createState() => _ReportDashboardScreenState();
}

class _ReportDashboardScreenState extends State<ReportDashboardScreen> {
  String? _selectedDeviceId;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _gymId;

  @override
  void initState() {
    super.initState();
    // Asynchron Gym-ID laden und danach Report initial triggern
    Future.microtask(_loadGymIdAndReport);
  }

  Future<void> _loadGymIdAndReport() async {
    final id = await context.read<GetSavedGymIdUseCase>().call();
    setState(() => _gymId = id);
    _loadReport();
  }

  void _loadReport() {
    if (_gymId == null || _gymId!.isEmpty) return;
    context.read<ReportBloc>().add(
      ReportLoadAll(
        gymId: _gymId!,
        deviceId: _selectedDeviceId,
        start: _startDate,
        end: _endDate,
      ),
    );
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now.subtract(const Duration(days: 30)),
      firstDate: DateTime(now.year - 2),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _startDate = picked);
      _loadReport();
    }
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _endDate = picked);
      _loadReport();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reporting-Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Filter-Zeile
            Row(
              children: [
                Expanded(child: _buildDeviceDropdown()),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _pickStartDate,
                  child: Text(
                    _startDate == null
                        ? 'Startdatum'
                        : '${_startDate!.day}.${_startDate!.month}.${_startDate!.year}',
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _pickEndDate,
                  child: Text(
                    _endDate == null
                        ? 'Enddatum'
                        : '${_endDate!.day}.${_endDate!.month}.${_endDate!.year}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Chart und Lade-/Fehlerzustand
            Expanded(
              child: BlocBuilder<ReportBloc, ReportState>(
                builder: (context, state) {
                  if (state is ReportLoading) {
                    return const Center(child: LoadingIndicator());
                  }
                  if (state is ReportLoadSuccess) {
                    return ReportChart(
                      start: _startDate,
                      end: _endDate,
                    );
                  }
                  if (state is ReportFailure) {
                    return Center(child: Text('Fehler: ${state.message}'));
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceDropdown() {
    if (_gymId == null || _gymId!.isEmpty) {
      return const Center(child: Text('Kein Gym ausgewählt'));
    }
    return FutureBuilder<List<DeviceInfo>>(
      future: context.read<FetchReportDevicesUseCase>().call(_gymId!),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const LoadingIndicator();
        }
        final devices = snap.data ?? [];
        return DropdownButtonFormField<String>(
          decoration: const InputDecoration(labelText: 'Gerät auswählen'),
          value: _selectedDeviceId,
          items: [
            const DropdownMenuItem(value: null, child: Text('Alle Geräte')),
            ...devices.map((d) => DropdownMenuItem(
                  value: d.id,
                  child: Text(d.name),
                )),
          ],
          onChanged: (val) {
            setState(() => _selectedDeviceId = val);
            _loadReport();
          },
        );
      },
    );
  }
}

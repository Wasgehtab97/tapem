import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/device_provider.dart';
import 'package:tapem/core/providers/muscle_group_provider.dart';
import 'package:tapem/features/device/domain/models/device.dart';
import 'package:tapem/features/muscle_group/presentation/widgets/device_muscle_assignment_sheet.dart';
import 'package:tapem/ui/common/search_and_filters.dart';
import 'package:tapem/ui/devices/device_card.dart';

class MuscleGroupAdminScreen extends StatefulWidget {
  const MuscleGroupAdminScreen({super.key});

  @override
  State<MuscleGroupAdminScreen> createState() => _MuscleGroupAdminScreenState();
}

class _MuscleGroupAdminScreenState extends State<MuscleGroupAdminScreen> {
  String _query = '';
  Set<String> _muscles = {};
  SortOrder _sort = SortOrder.az;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final gymId = auth.gymCode ?? '';
      context.read<DeviceProvider>().loadDevices(gymId);
      context.read<MuscleGroupProvider>().loadGroups(context);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onQuery(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => _query = v);
    });
  }

  List<Device> _filtered(List<Device> devices) {
    final q = _query.toLowerCase();
    final res = devices
        .where((d) {
          if (d.isMulti) return false;
          final nameMatch = d.name.toLowerCase().contains(q);
          final brandMatch = d.description.toLowerCase().contains(q);
          return nameMatch || brandMatch;
        })
        .where((d) {
          if (_muscles.isEmpty) return true;
          final all = {...d.primaryMuscleGroups, ...d.secondaryMuscleGroups};
          return all.any(_muscles.contains);
        })
        .toList();
    res.sort((a, b) =>
        _sort == SortOrder.az ? a.name.compareTo(b.name) : b.name.compareTo(a.name));
    return res;
  }

  Future<void> _openAssignSheet(Device d) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DeviceMuscleAssignmentSheet(
        deviceId: d.uid,
        deviceName: d.name,
        initialPrimary: d.primaryMuscleGroups,
        initialSecondary: d.secondaryMuscleGroups,
      ),
    );
    final auth = context.read<AuthProvider>();
    final gymId = auth.gymCode ?? '';
    await context.read<DeviceProvider>().loadDevices(gymId);
    await context.read<MuscleGroupProvider>().loadGroups(context);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final deviceProv = context.watch<DeviceProvider>();
    final devices = _filtered(deviceProv.devices);

    return Scaffold(
      appBar: AppBar(title: const Text('Muskelgruppen verwalten')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: SearchAndFilters(
                query: _query,
                onQuery: _onQuery,
                sort: _sort,
                onSort: (v) => setState(() => _sort = v),
                muscleFilterIds: _muscles,
                onMuscleFilter: (v) => setState(() => _muscles = v),
              ),
            ),
            Expanded(
              child: deviceProv.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : devices.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.5,
                              child:
                                  const Center(child: Text('Keine Geräte gefunden')),
                            ),
                          ],
                        )
                      : ListView.builder(
                          itemCount: devices.length,
                          itemBuilder: (ctx, i) {
                            final d = devices[i];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: DeviceCard(
                                device: d,
                                onTap: () => _openAssignSheet(d),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

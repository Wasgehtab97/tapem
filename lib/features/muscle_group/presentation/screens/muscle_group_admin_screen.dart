import 'dart:async';
import 'package:flutter/material.dart' hide SearchBar;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/core/providers/muscle_group_provider.dart';
import 'package:tapem/features/device/domain/models/device.dart';
import 'package:tapem/features/muscle_group/presentation/widgets/device_muscle_assignment_sheet.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/ui/common/filter_chips_row.dart';
import 'package:tapem/ui/common/search_and_filters.dart';
import 'package:tapem/ui/common/search_bar.dart';
import 'package:tapem/ui/devices/device_card.dart';
import 'package:tapem/core/providers/device_provider.dart';
import 'package:tapem/features/device/providers/workout_day_controller_provider.dart';

class MuscleGroupAdminScreen extends ConsumerStatefulWidget {
  const MuscleGroupAdminScreen({super.key});

  @override
  ConsumerState<MuscleGroupAdminScreen> createState() =>
      _MuscleGroupAdminScreenState();
}

class _MuscleGroupAdminScreenState extends ConsumerState<MuscleGroupAdminScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';
  Set<String> _muscles = {};
  SortOrder _sort = SortOrder.az;
  Timer? _debounce;
  DeviceProvider? _deviceProvider;
  String? _sessionKey;
  VoidCallback? _deviceListener;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = ref.read(authControllerProvider);
      final gymId = auth.gymCode ?? '';
      final controller = ref.read(workoutDayControllerProvider);
      final session = controller.addOrFocusSession(
        gymId: gymId,
        deviceId: '__muscle_admin__',
        exerciseId: '__muscle_admin__',
        userId: auth.userId!,
      );
      _deviceProvider = session.provider;
      _sessionKey = session.key;
      _deviceListener = () {
        if (mounted) {
          setState(() {});
        }
      };
      _deviceProvider?.addListener(_deviceListener!);
      session.provider.loadDevices(gymId, auth.userId!);
      ref.read(muscleGroupProvider).loadGroups(context);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    final key = _sessionKey;
    if (key != null) {
      ref.read(workoutDayControllerProvider).closeSession(key);
    }
    if (_deviceListener != null && _deviceProvider != null) {
      _deviceProvider!.removeListener(_deviceListener!);
    }
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
    final res = await showModalBottomSheet<Map<String, List<String>>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => DeviceMuscleAssignmentSheet(
        deviceId: d.uid,
        deviceName: d.name,
        initialPrimary: d.primaryMuscleGroups,
        initialSecondary: d.secondaryMuscleGroups,
      ),
    );
    if (res != null) {
      _deviceProvider?.patchDeviceGroups(
        d.uid,
        res['primary'] ?? [],
        res['secondary'] ?? [],
      );
      ref.read(gymProvider).patchDeviceGroups(
        d.uid,
        res['primary'] ?? [],
        res['secondary'] ?? [],
      );
    }
  }

  Future<void> _resetAssignments(Device d) async {
    final loc = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.resetMuscleGroups),
        content: Text(loc.resetMuscleGroupsConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(loc.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(loc.resetMuscleGroups),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await ref
        .read(muscleGroupProvider)
        .updateDeviceAssignments(context, d.uid, [], []);
    _deviceProvider?.applyMuscleAssignments(d.uid, [], []);
    HapticFeedback.lightImpact();
  }

  void _resetFilters() {
    _controller.clear();
    setState(() {
      _query = '';
      _muscles = {};
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = _deviceProvider;
    if (provider == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final devices = _filtered(provider.devices);
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: Text(loc.muscleAdminTitle),
            actions: [
              IconButton(
                tooltip: loc.resetFilters,
                icon: const Icon(Icons.filter_alt_off),
                onPressed: _resetFilters,
              ),
            ],
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SearchHeaderDelegate(
              child: Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  children: [
                    SearchBar(
                      controller: _controller,
                      onChanged: _onQuery,
                      hint: loc.multiDeviceSearchHint,
                    ),
                    const SizedBox(height: 12),
                    FilterChipsRow(
                      sort: _sort,
                      onSort: (v) => setState(() => _sort = v),
                      muscleFilterIds: _muscles,
                      onMuscleFilter: (v) => setState(() => _muscles = v),
                      onReset: _resetFilters,
                    ),
                  ],
                ),
              ),
              height: 120,
            ),
          ),
          if (provider.isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (devices.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text(loc.gymNoDevices)),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  final d = devices[i];
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: DeviceCard(
                      device: d,
                      onTap: () => _openAssignSheet(d),
                      onAssignMuscles: () => _openAssignSheet(d),
                      onResetMuscles: () => _resetAssignments(d),
                    ),
                  );
                },
                childCount: devices.length,
              ),
            ),
        ],
      ),
    );
  }
}

class _SearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;
  _SearchHeaderDelegate({required this.child, required this.height});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _SearchHeaderDelegate oldDelegate) {
    return oldDelegate.child != child || oldDelegate.height != height;
  }
}

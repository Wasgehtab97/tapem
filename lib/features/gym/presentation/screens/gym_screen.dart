import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/gym_provider.dart';
import 'package:tapem/core/providers/muscle_group_provider.dart';
import 'package:tapem/core/recent_devices_store.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/features/device/domain/models/device.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/ui/common/search_and_filters.dart';
import 'package:tapem/ui/devices/device_card.dart';

class GymScreen extends StatefulWidget {
  const GymScreen({super.key});

  @override
  State<GymScreen> createState() => _GymScreenState();
}

class _GymScreenState extends State<GymScreen>
    with AutomaticKeepAliveClientMixin {
  String _query = '';
  Set<String> _muscles = {};
  SortOrder _sort = SortOrder.az;
  List<String> _recent = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final gym = context.read<GymProvider>();
      final groups = context.read<MuscleGroupProvider>();
      final code = auth.gymCode;
      if (code != null && code.isNotEmpty) {
        gym.loadGymData(code);
        groups.loadGroups(context);
      }
    });
  }

  Future<void> _loadRecent(String gymId) async {
    final ids = await RecentDevicesStore.getOrder(gymId);
    if (mounted && !listEquals(ids, _recent)) {
      setState(() => _recent = ids);
    }
  }

  List<Device> _filtered(List<Device> devices) {
    final q = _query.toLowerCase();
    var res = devices.where((d) {
      final nameMatch = d.name.toLowerCase().contains(q);
      final brandMatch = d.description.toLowerCase().contains(q);
      return nameMatch || brandMatch;
    }).where((d) {
      if (d.isMulti || _muscles.isEmpty) return true;
      final all = {...d.primaryMuscleGroups, ...d.secondaryMuscleGroups};
      return all.any(_muscles.contains);
    }).toList();
    res.sort((a, b) {
      if (_sort == SortOrder.recent) {
        final ai = _recent.indexOf(a.uid);
        final bi = _recent.indexOf(b.uid);
        if (ai == -1 && bi == -1) {
          return a.name.compareTo(b.name);
        }
        if (ai == -1) return 1;
        if (bi == -1) return -1;
        return ai.compareTo(bi);
      }
      return _sort == SortOrder.az
          ? a.name.compareTo(b.name)
          : b.name.compareTo(a.name);
    });
    return res;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final loc = AppLocalizations.of(context)!;
    final auth = context.read<AuthProvider>();
    final gymProv = context.watch<GymProvider>();
    final gymId = auth.gymCode ?? '';

    if (gymProv.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (gymProv.error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(loc.gymTitle)),
        body: Center(child: Text('${loc.errorPrefix}: ${gymProv.error}')),
      );
    }
    if (_sort == SortOrder.recent) {
      _loadRecent(gymId);
    }
    final devices = _filtered(gymProv.devices);

    return Scaffold(
      appBar: AppBar(title: Text(loc.gymTitle)),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: SearchAndFilters(
                query: _query,
                onQuery: (v) => setState(() => _query = v),
                sort: _sort,
                onSort: (v) {
                  setState(() => _sort = v);
                  if (v == SortOrder.recent) {
                    _loadRecent(gymId);
                  }
                },
                muscleFilterIds: _muscles,
                onMuscleFilter: (v) => setState(() => _muscles = v),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => gymProv.loadGymData(gymId),
                child: devices.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.5,
                            child: Center(child: Text(loc.gymNoDevices)),
                          ),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: devices.length,
                        itemBuilder: (ctx, i) {
                          final d = devices[i];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: DeviceCard(
                              device: d,
                              onTap: () {
                                final nav = Navigator.of(context);
                                final idStr = d.uid;
                                if (d.isMulti) {
                                  nav.pushNamed(
                                    AppRouter.exerciseList,
                                    arguments: {
                                      'gymId': gymId,
                                      'deviceId': idStr,
                                    },
                                  );
                                } else {
                                  nav.pushNamed(
                                    AppRouter.device,
                                    arguments: {
                                      'gymId': gymId,
                                      'deviceId': idStr,
                                      'exerciseId': idStr,
                                    },
                                  );
                                }
                              },
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// lib/features/gym/presentation/screens/gym_screen.dart

import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:collection/collection.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';

import 'package:tapem/app_router.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/gym_provider.dart';
import 'package:tapem/core/providers/muscle_group_provider.dart';
import 'package:tapem/features/device/domain/models/device.dart';
import '../widgets/device_card.dart';

class GymScreen extends StatefulWidget {
  const GymScreen({Key? key}) : super(key: key);

  @override
  State<GymScreen> createState() => _GymScreenState();
}

class _GymScreenState extends State<GymScreen> {
  final TextEditingController _searchCtr = TextEditingController();
  final ScrollController _scrollCtr = ScrollController();
  final Map<String, GlobalKey> _headerKeys = {};
  Timer? _debounce;
  String _query = '';
  final Set<String> _groupFilter = {};
  bool _single = true;
  bool _multi = true;

  @override
  void initState() {
    super.initState();
    _searchCtr.addListener(_onQueryChanged);
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

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtr.dispose();
    _scrollCtr.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => _query = _searchCtr.text);
    });
  }

  List<Device> _applyFilters(List<Device> devices) {
    var res =
        devices.where((d) {
          final q = _query.toLowerCase();
          final matches =
              d.name.toLowerCase().contains(q) ||
              d.description.toLowerCase().contains(q);
          return matches;
        }).toList();
    if (_groupFilter.isNotEmpty) {
      res =
          res
              .where((d) => d.muscleGroups.any((g) => _groupFilter.contains(g)))
              .toList();
    }
    if (_single && !_multi) {
      res = res.where((d) => !d.isMulti).toList();
    } else if (_multi && !_single) {
      res = res.where((d) => d.isMulti).toList();
    }
    return res;
  }

  Map<String, List<Device>> _groupByLetter(List<Device> devices) {
    final groups = groupBy(
      devices,
      (Device d) => d.name.isNotEmpty ? d.name[0].toUpperCase() : '#',
    );
    final sortedKeys = groups.keys.toList()..sort();
    return {for (final k in sortedKeys) k: groups[k]!};
  }

  int _crossAxisCount(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= 900) return 3;
    if (w >= 600) return 2;
    return 1;
  }

  void _jumpToLetter(String letter) {
    final key = _headerKeys[letter];
    if (key != null && key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: AppDurations.short,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final auth = context.read<AuthProvider>();
    final gymProv = context.watch<GymProvider>();
    final groupProv = context.watch<MuscleGroupProvider>();
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

    final devices = _applyFilters(gymProv.devices);
    final grouped = _groupByLetter(devices);
    final letters = grouped.keys.toList();

    return Scaffold(
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async => gymProv.loadGymData(gymId),
            child: CustomScrollView(
              controller: _scrollCtr,
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  pinned: true,
                  title: Text(loc.gymTitle),
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surface.withOpacity(0.9),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SearchHeaderDelegate(
                    controller: _searchCtr,
                    groups:
                        groupProv.groups
                            .map((g) => g.region.name)
                            .toSet()
                            .toList(),
                    selectedGroups: _groupFilter,
                    showSingle: _single,
                    showMulti: _multi,
                    onGroupToggle:
                        (g) => setState(() {
                          if (_groupFilter.contains(g)) {
                            _groupFilter.remove(g);
                          } else {
                            _groupFilter.add(g);
                          }
                        }),
                    onToggleSingle: (v) => setState(() => _single = v),
                    onToggleMulti: (v) => setState(() => _multi = v),
                  ),
                ),
                if (devices.isEmpty)
                  SliverFillRemaining(
                    child: Center(child: Text(loc.gymNoDevices)),
                  )
                else
                  for (final entry in grouped.entries)
                    SliverStickyHeader(
                      header: Container(
                        key: _headerKeys.putIfAbsent(
                          entry.key,
                          () => GlobalKey(),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        color: Theme.of(context).colorScheme.surface,
                        child: Text(
                          entry.key,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      sliver: SliverPadding(
                        padding: const EdgeInsets.all(8),
                        sliver: SliverMasonryGrid.count(
                          crossAxisCount: _crossAxisCount(context),
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childCount: entry.value.length,
                          itemBuilder: (c, i) {
                            final d = entry.value[i];
                            return DeviceCard(
                              device: d,
                              onTap: () {
                                final args = {
                                  'gymId': gymId,
                                  'deviceId': d.uid,
                                  'exerciseId': d.uid,
                                };
                                Navigator.of(
                                  context,
                                ).pushNamed(AppRouter.device, arguments: args);
                              },
                            );
                          },
                        ),
                      ),
                    ),
              ],
            ),
          ),
          Positioned(
            right: 4,
            top: 100,
            bottom: 100,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final l in letters)
                  GestureDetector(
                    onTap: () => _jumpToLetter(l),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Text(
                        l,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  final TextEditingController controller;
  final List<String> groups;
  final Set<String> selectedGroups;
  final bool showSingle;
  final bool showMulti;
  final ValueChanged<String> onGroupToggle;
  final ValueChanged<bool> onToggleSingle;
  final ValueChanged<bool> onToggleMulti;

  _SearchHeaderDelegate({
    required this.controller,
    required this.groups,
    required this.selectedGroups,
    required this.showSingle,
    required this.showMulti,
    required this.onGroupToggle,
    required this.onToggleSingle,
    required this.onToggleMulti,
  });

  @override
  double get maxExtent => 128;

  @override
  double get minExtent => 128;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.9),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Search devices',
              prefixIcon: const Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Single'),
                  selected: showSingle,
                  onSelected: onToggleSingle,
                ),
                const SizedBox(width: 4),
                FilterChip(
                  label: const Text('Multi'),
                  selected: showMulti,
                  onSelected: onToggleMulti,
                ),
                const SizedBox(width: 4),
                for (final g in groups)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: FilterChip(
                      label: Text(g),
                      selected: selectedGroups.contains(g),
                      onSelected: (_) => onGroupToggle(g),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _SearchHeaderDelegate oldDelegate) {
    return oldDelegate.groups != groups ||
        oldDelegate.selectedGroups != selectedGroups ||
        oldDelegate.showSingle != showSingle ||
        oldDelegate.showMulti != showMulti;
  }
}
